{:ok, _} = Application.ensure_all_started(:ecto_sql)

defmodule Geo.Test.Helper do
end

ExUnit.start()
