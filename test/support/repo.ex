defmodule GeoSQL.Test.PostGIS.Repo do
  use Ecto.Repo, otp_app: :geo_sql, adapter: Ecto.Adapters.Postgres
end

# For the migrations.
GeoSQL.init(GeoSQL.Test.PostGIS.Repo, json: Jason, decode_binary: :reference)
