defmodule GeoSQL.PostGIS.Test.Repo do
  use Ecto.Repo, otp_app: :geo_sql, adapter: Ecto.Adapters.Postgres
end
