defmodule GeoSQL do
  @moduledoc """
  GeoSQL provides access to GIS functions in SQL databases. Currently supported are PostGIS 3.x and SpatialLite.

  SQL functions are separated by their appearance in standards (e.g. SQL/MM2 vs SQL/MM3), category or topic
  (such as MM3 topological functions) as well as their availability in specific implementations.

  This makes usage of feature sets self-documenting in the code, allowing developers to adopt or avoid
  calls that are (or are not) available in the databases in use.

  Where there are subtle differences between implementations of the same functions, GeoSQL strives to
  hide those differences behind single function calls.
  """

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
