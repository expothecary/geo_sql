import Config

test_repos =
  (System.get_env("GEOSQL_TEST_BACKENDS") || "pgsql,sqlite3,mysql")
  |> String.split(",")
  |> Enum.reduce([], fn backend, acc ->
    case backend do
      "pgsql" -> [GeoSQL.Test.PostGIS.Repo | acc]
      "mysql" -> [GeoSQL.Test.MySQL.Repo | acc]
      "sqlite3" -> [GeoSQL.Test.SpatiaLite.Repo, GeoSQL.Test.Geopackage.Repo | acc]
    end
  end)

config :geo_sql, ecto_repos: test_repos

config :geo_sql, GeoSQL.Test.PostGIS.Repo,
  url: "ecto://postgres@localhost/geosql_tests",
  types: GeoSQL.PostgrexTypes,
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/repo/postgis",
  testing_primary: true

config :geo_sql, GeoSQL.Test.MySQL.Repo,
  host: "localhost",
  username: "testing",
  password: "testing",
  protocol: :tcp,
  database: "geosql_tests",
  types: GeoSQL.PostgrexTypes,
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/repo/mysql",
  testing_primary: true,
  show_sensitive_data_on_connection_error: true

config :geo_sql, GeoSQL.Test.SpatiaLite.Repo,
  database: "geo_sql_test.sqlite3",
  pool_size: 20,
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/repo/sqlite3",
  load_extensions: ["mod_spatialite"],
  testing_primary: true

config :geo_sql, GeoSQL.Test.Geopackage.Repo,
  database: "test/support/geopackage_test.gpkg",
  pool_size: 20,
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/repo/geopackage",
  load_extensions: ["mod_spatialite"]

config :exqlite,
  type_extensions: [GeoSQL.SpatiaLite.TypeExtension]

config :ecto_sqlite3,
  type_extensions: [GeoSQL.SpatiaLite.TypeExtension]

# Print only warnings and errors during test
config :logger, level: :warning
