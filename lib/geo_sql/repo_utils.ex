defmodule GeoSQL.RepoUtils do
  @moduledoc false
  @default_adapter Ecto.Adapters.Postgres

  defmacro adapter(repo) do
    quote do
      if unquote(repo) == nil do
        unquote(@default_adapter)
      else
        Macro.expand(unquote(repo), __CALLER__).__adapter__()
      end
    end
  end
end
