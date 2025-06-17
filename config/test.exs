import Config

test_repos =
  (System.get_env("GEOSQL_TEST_BACKENDS") || "pgsql,sqlite3")
  |> String.split(",")
  |> Enum.map(fn backend ->
    case backend do
      "pgsql" -> GeoSQL.Test.PostGIS.Repo
      "sqlite3" -> GeoSQL.Test.SQLite3.Repo
    end
  end)

config :geo_sql, ecto_repos: test_repos

config :geo_sql, GeoSQL.Test.PostGIS.Repo,
  url: "ecto://postgres@localhost/geosql_tests",
  types: GeoSQL.PostgrexTypes,
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/repo/postgis"

config :geo_sql, GeoSQL.Test.SQLite3.Repo,
  database: "geo_sql_test.sqlite3",
  types: GeoSQL.PostgrexTypes,
  pool_size: 20,
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/repo/sqlite3",
  load_extensions: ["mod_spatialite"]

# Print only warnings and errors during test
config :logger, level: :warning
