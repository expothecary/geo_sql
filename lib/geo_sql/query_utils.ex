defmodule GeoSQL.QueryUtils do
  @moduledoc "Utilities to make queries easier to produce"

  defmacro __using__(_) do
    quote do
      require GeoSQL.QueryUtils
      alias GeoSQL.QueryUtils
    end
  end

  defmodule WKB do
    @moduledoc """
    A wrapper around WKB binaries to allow them to be differentiated from other binaries.

    Mostly useful for type adapters.

    See `GeoSQL.QueryUtils.wrap_wkb/2`
    """
    defstruct data: <<>>
    @type t :: %__MODULE__{}
  end

  require GeoSQL.RepoUtils

  @doc """
  Used to cast data to geometries in a backend-neutral fashion. This can be necessary
  when, for example, passing geogrpahy types to geometry functions in PostGIS.
  """
  defmacro cast_to_geometry(geo, repo \\ nil) do
    case GeoSQL.RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("CAST(? AS geometry)", unquote(geo))

      _ ->
        quote do: unquote(geo)
    end
  end

  @doc """
  Used to wrap WKB literals in a portable fashion. When used in an ecto query,
  the return value will need to be pinned in the query.

  Example:

      from(g in GeoType,
          select: g.linestring == MM2.linestring_from_wkb(^QueryUtils.wrap_wkb(wkb, MyApp.Repo))
  """
  @spec wrap_wkb(wkb :: binary, Ecto.Repo.t()) :: GeoSQL.QueryUtils.WKB.t()
  defmacro wrap_wkb(wkb, repo) do
    case GeoSQL.RepoUtils.adapter(repo) do
      Ecto.Adapters.SQLite3 ->
        quote do: %GeoSQL.QueryUtils.WKB{data: unquote(wkb)}

      _ ->
        quote do: unquote(wkb)
    end
  end

  @spec as_positional_params(options :: Keyword.t(), allowed_keys :: [:atom]) ::
          {param_string :: String.t(), params :: list}
  @doc """
  Turn a set of options into positional parameters, checking that the keys are allowed.

  This makes it easier to implement support for SQL functions which support a variable number
  of options (often flags to enable/disable functionality). The user can provide only the
  parameters they wish to provide, and this will turn them into a template string with the
  necessary number of `?`s and the values included.

  The `allowed_keys` must be provided in the order they appear in the SQL function.
  ### Example

  For an SQL function `my_func(int foo, string bar)` with variant
  `my_func(int foo, stering bar, boolean baz)`:

      foo = 100
      valid_params = [:bar, :baz]
      {param_string, params} = GeoSQL.QueryUtils.as_positional_params([foo: 100, bar: "names"], valid_params)
      {", ?", ["names"]}
      from(r in Schemna, where: fragment()"my_func(?\#{param_string})", [foo | params])
  """
  def as_positional_params(options, allowed_keys)
      when is_list(options) and is_list(allowed_keys) do
    values =
      Enum.reduce_while(allowed_keys, [], fn key, acc ->
        case Keyword.get(options, key) do
          nil -> {:halt, acc}
          value -> {:cont, [value | acc]}
        end
      end)

    {String.duplicate(", ?", Enum.count(values)), Enum.reverse(values)}
  end

  @doc """
  Turn a set of options into named parameters using the `=>` parameter naming operator,
  checking that the keys are allowed.

  This can only be used with functions that actually have named paramters, which is mostly
  user-provided functions.
  """
  @spec as_named_params(options :: Keyword.t(), allowed_keys :: [:atom]) ::
          {param_string :: String.t(), params :: list}
  def as_named_params(options, allowed_keys) when is_list(options) and is_list(allowed_keys) do
    Keyword.validate!(options, allowed_keys)

    {
      Enum.map(options, fn {key, _value} -> "#{key} => ?" end) |> Enum.join(", "),
      Enum.map(options, fn {_key, value} -> value end)
    }
  end

  @doc """
  When returning a single geometry in an Ecto query `select` clause, geometries may
  be returned as raw binaries in some backends.

  To get `Geo` structs from such queries, pass the results of the query to `decode_geometry/2`
  to guarantee corectly decoded geometries regardless of the backend being used.

  ```elixir
        from(location in Location, select: MM2.boundary(location.geom))
        |> Repo.all()
        |> QueryUtils.decode_geometry(Repo)
  ```
  """
  def decode_geometry(%{} = geometry, _repo), do: geometry
  def decode_geometry(nil, _repo), do: nil
  def decode_geometry([], _repo), do: []

  def decode_geometry(query_result, repo) when is_binary(query_result) do
    case repo.__adapter__() do
      Ecto.Adapters.Postgres -> query_result
      Ecto.Adapters.SQLite3 -> decode_one(GeoSQL.SpatialLite.TypeExtension, query_result)
    end
  end

  def decode_geometry(query_results, repo) when is_list(query_results) do
    case repo.__adapter__() do
      Ecto.Adapters.Postgres ->
        query_results

      Ecto.Adapters.SQLite3 ->
        Enum.map(
          query_results,
          fn query_result -> decode_one(GeoSQL.SpatialLite.TypeExtension, query_result) end
        )
    end
  end

  @doc """
  When returning geometries as part of a map or list Ecto query `select` clause (as opposed to
  returning an `Ecto.Schema` struct, where geometries are automatically decoded), geometries may
  be returned as raw binaries in some backends.

  To get `Geo` structs from these queries, pass the results of the query to `decode_geometry/3`.

  The third `fields_to_decode` parameter is a list of the fields to decode. When the query
  results are lists, the `fields_to_decode` must be a list of integers that are the indexes
  of the elements to decode:

  ```elixir
        from(location in Location, select: [location.name, MM2.boundary(location.geom)])
        |> Repo.all()
        |> QueryUtils.decode_geometry(Repo, [1])
  ```

  When returning a map, `fields_to_decode` must be a list of field names:


  ```elixir
        from(location in Location, select: %{name: location.name, boundary: MM2.boundary(location.geom)]})
        |> Repo.all()
        |> QueryUtils.decode_geometry(Repo, ["boundary])
  ```
  """
  def decode_geometry(nil, _repo, _fields_to_decode), do: nil
  def decode_geometry([], _repo, _fields_to_decode), do: []

  def decode_geometry(query_results, repo, fields_to_decode) do
    case repo.__adapter__() do
      Ecto.Adapters.Postgres ->
        query_results

      Ecto.Adapters.SQLite3 ->
        decode_all(query_results, GeoSQL.SpatialLite.TypeExtension, fields_to_decode)
    end
  end

  defp decode_all(%{} = query_results, type_extension, fields_to_decode) do
    Enum.reduce(fields_to_decode, query_results, fn field, query_result ->
      encoded_field = Map.get(query_result, field)

      if encoded_field == nil do
        query_result
      else
        Map.put(query_result, field, decode_one(type_extension, encoded_field))
      end
    end)
  end

  defp decode_all([head | _] = query_results, type_extension, fields_to_decode)
       when is_list(head) or is_map(head) do
    Enum.map(query_results, fn query_result ->
      decode_all(query_result, type_extension, fields_to_decode)
    end)
  end

  defp decode_all(query_result, type_extension, fields_to_decode)
       when is_list(query_result) do
    query_result
    |> Enum.with_index(fn encoded_field, index ->
      if Enum.member?(fields_to_decode, index) do
        decode_one(type_extension, encoded_field)
      else
        encoded_field
      end
    end)
  end

  defp decode_one(type_extension, encoded_field) do
    case type_extension.decode_geometry(encoded_field) do
      {:ok, successfully_decoded_field} -> successfully_decoded_field
      :error -> encoded_field
      {:error, _} -> encoded_field
    end
  end
end
