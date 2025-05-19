defmodule GeoSQL do
  @moduledoc """

  """
  def init(repo) do
    repo
    |> repo_adapter()
    |> init_spatial_capabilities(repo)
  end

  def repo_adapter(repo) do
    repo
    |> Application.get_env(:yaybr_core)
    |> Keyword.get(:adapter)
  end

  defp init_spatial_capabilities(Ecto.Adapters.SQLite3, repo) do
    apply(Ecto.Adapters.SQLite3, :query, [repo, "SELECT InitSpatialMetadata()"])
  end

  defp init_spatial_capabilities(_, _repo) do
    {:ok, :none}
  end
end
