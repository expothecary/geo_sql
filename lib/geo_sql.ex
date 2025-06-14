defmodule GeoSQL do
  @moduledoc """
  GeoSQL provides access to GIS functions in SQL databases via Ecto. PostGIS 3.x and SpatialLite are
  currently supported.

  SQL functions are separated by their appearance in standards (e.g. SQL/MM2 vs SQL/MM3), category or topic
  (such as topological and 3D functions), as well as their availability in specific implementations.

  This makes usage of feature sets self-documenting in the code, allowing developers to adopt or avoid
  functions that are not available in the databases the application uses.

  Where there are subtle differences between implementations of the same functions, GeoSQL strives to
  hide those differences behind single function calls.
  """

  @type fragment :: term

  def init(repo) when is_atom(repo) do
    repo.__adapter__()
    |> init_spatial_capabilities(repo)
  end

  defp init_spatial_capabilities(Ecto.Adapters.SQLite3, repo) do
    apply(Ecto.Adapters.SQLite3, :query, [repo, "SELECT InitSpatialMetadata()"])
  end

  defp init_spatial_capabilities(_, _repo) do
    {:ok, :none}
  end
end
