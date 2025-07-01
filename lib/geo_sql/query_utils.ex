defmodule GeoSQL.QueryUtils do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      require GeoSQL.QueryUtils
      alias GeoSQL.QueryUtils
    end
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

  @spec wrap_wkb(wkb :: binary, Ecto.Repo.t()) :: GeoSQL.Geometry.WKB.t()
  defmacro wrap_wkb(wkb, repo) do
    case GeoSQL.RepoUtils.adapter(repo) do
      Ecto.Adapters.SQLite3 ->
        quote do: %GeoSQL.Geometry.WKB{data: unquote(wkb)}

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
      {param_string, params} = PostGIS.Utils.as_positional_params([foo: 100, bar: "names"], valid_params)
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
end
