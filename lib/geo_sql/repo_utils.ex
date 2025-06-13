defmodule GeoSQL.RepoUtils do
  @default_adapter Ecto.Adapters.Postgres

  defmacro adapter(nil) do
    @default_adapter
  end

  defmacro adapter(repo) do
    quote do: Macro.expand(unquote(repo), __CALLER__).__adapter__()
  end
end
