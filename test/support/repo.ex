defmodule GeoSQL.Test.PostGIS.Repo do
  use Ecto.Repo, otp_app: :geo_sql, adapter: Ecto.Adapters.Postgres
end

defmodule GeoSQL.Test.SQLite3.Repo do
  use Ecto.Repo, otp_app: :geo_sql, adapter: Ecto.Adapters.SQLite3
end

# For the migrations.
GeoSQL.init(GeoSQL.Test.PostGIS.Repo, json: Jason, decode_binary: :reference)
