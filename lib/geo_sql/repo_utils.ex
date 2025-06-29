defmodule GeoSQL.RepoUtils do
  @moduledoc false
  @default_adapter Application.compile_env(:geo_sql, :default_adapter, Ecto.Adapters.Postgres)

  defmacro __using__(_) do
    quote do
      require GeoSQL.RepoUtils
      alias GeoSQL.RepoUtils
    end
  end

  def adapter_for(repo) do
    case repo do
      nil ->
        unquote(@default_adapter)

      _ ->
        repo.__adapter__()
    end
  end

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
