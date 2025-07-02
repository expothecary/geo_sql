defmodule GeoSQL.RepoUtils do
  @moduledoc """
  Helpers for working with Ecto Repo modules.
  """
  @default_adapter Application.compile_env(:geo_sql, :default_adapter, Ecto.Adapters.Postgres)

  defmacro __using__(_) do
    quote do
      require GeoSQL.RepoUtils
      alias GeoSQL.RepoUtils
    end
  end

  @doc """
  Returns an adapter for a given repo, with a sensible default on `nil`.

  As the details of a given SQL call may differ from implementation
  to implentation, many of the functions in GeoSQL rely on examining
  the repo module to determine which variant to utilize.

  This function provides a convenience to discover the backend
  adapter given a repo. If no adapter is provided, it defaults to
  the configured preference, ultimately falling back to PostgreSQL.

  To configure the default, adapt this line in `config.exs`:
    config :geo_sql, default_adapter: Ecto.Adapters.<PreferredAdapter>
  """
  @spec adapter_for(Ecto.Repo.t() | nil) :: module()
  def adapter_for(repo) do
    case repo do
      nil ->
        unquote(@default_adapter)

      _ ->
        repo.__adapter__()
    end
  end

  @doc """
  Macro version of `adapter_for/1` for use where a function is not
  usable or less ergonomic.
  """
  @spec adapter(Ecto.Repo.t() | nil) :: module()
  defmacro adapter(repo) do
    quote do
      case unquote(repo) do
        {_, _, nil} ->
          unquote(@default_adapter)

        nil ->
          unquote(@default_adapter)

        _ ->
          Macro.expand(unquote(repo), __CALLER__).__adapter__()
      end
    end
  end
end
