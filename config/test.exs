import Config

config :geo_sql, ecto_repos: [GeoSQL.Test.PostGIS.Repo]

config :geo_sql, GeoSQL.Test.PostGIS.Repo,
  url: "ecto://postgres@localhost/geosql_tests",
  types: GeoSQL.PostgrexTypes,
  pool: Ecto.Adapters.SQL.Sandbox

# Print only warnings and errors during test
config :logger, level: :warning
