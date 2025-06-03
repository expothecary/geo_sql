import Config

config :geo_sql, ecto_repos: [GeoSQL.PostGIS.Test.Repo]

config :geo_sql, GeoSQL.PostGIS.Test.Repo,
  url: "ecto://postgres@localhost/geosql_tests",
  types: GeoSQL.PostgrexTypes

# Print only warnings and errors during test
config :logger, level: :warning
