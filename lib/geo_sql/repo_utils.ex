defmodule GeoSQL.RepoUtils do
  @moduledoc false
  @default_adapter Ecto.Adapters.Postgres

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
