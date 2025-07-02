defmodule GeoSQL do
  @moduledoc """
  GeoSQL provides access to GIS functions in SQL databases via Ecto. PostGIS 3.x and Spatialite are
  currently supported.

  SQL functions are sorted into modules by their appearance in standards (e.g. SQL/MM2 vs SQL/MM3),
  category or topic (such as topological and 3D functions), as well as their availability in
  specific implementations. This includes the following modules:

    * `GeoSQL.MM2`: functions from the SQL/MM v2 standard
    * `GeoSQL.MM3`: functions from the SQL/MM v3 standard
    * `GeoSQL.Common`: non-standard functions that are widely available
    * `GeoSQL.PostGIS`: functions only found in PostGIS

  This makes usage of feature sets self-documenting in the code, allowing developers to adopt or avoid
  functions that are not available in the databases the application uses.

  Where there are subtle differences between implementations of the same functions, GeoSQL strives to
  hide those differences behind single function calls.

  The `GeoSQL.Geometry` module provides access to geometric types in Ecto schemas.
  """

  @type fragment :: term
  @type geometry_input :: GeoSQL.Geometry.t() | fragment
  @type init_option :: {:json, atom} | {:decode_binary, :copy | :reference}
  @type init_options :: [init_option]

  @spec init(Ecto.Repo.t(), init_options) :: :ok
  def init(repo, opts \\ [json: Jason, decode_binary: :copy]) when is_atom(repo) do
    repo.__adapter__()
    |> register_types(repo, opts)
    |> init_spatial_capabilities(repo, opts)

    :ok
  end

  defp init_spatial_capabilities(Ecto.Adapters.SQLite3 = adapter, repo, _opts) do
    run_query(repo, "SELECT InitSpatialMetadata()")
    adapter
  end

  defp init_spatial_capabilities(adapter, _repo, _opts) do
    adapter
  end

  defp register_types(Ecto.Adapters.Postgres = adapter, repo, opts) do
    types_module =
      repo.config()
      |> Keyword.get_lazy(:types, fn ->
        [app | _] = Module.split(repo)
        Module.concat(app, PostgresTypes)
      end)

    if not Code.ensure_loaded?(types_module) do
      Postgrex.Types.define(
        types_module,
        GeoSQL.PostGIS.Extension.extensions() ++ Ecto.Adapters.Postgres.extensions(),
        opts
      )
    end

    adapter
  end

  defp register_types(adapter, _repo, _opts), do: adapter

  defp run_query(repo, sql) do
    try do
      Ecto.Adapters.SQL.query!(repo.get_dynamic_repo(), sql)
      :ok
    rescue
      _ -> :error
    end
  end
end
