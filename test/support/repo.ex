defmodule GeoSQL.Test.PostGIS.Repo do
  use Ecto.Repo, otp_app: :geo_sql, adapter: Ecto.Adapters.Postgres
end

defmodule TestSchema.Location do
  use Ecto.Schema

  schema "locations" do
    field(:name, :string)
    field(:geom, GeoSQL.Geometry)
  end
end

defmodule TestSchema.Geographies do
  use Ecto.Schema

  schema "geographies" do
    field(:name, :string)
    field(:geom, GeoSQL.Geometry)
  end
end

defmodule TestSchema.LocationMulti do
  use Ecto.Schema

  schema "location_multi" do
    field(:name, :string)
    field(:geom, GeoSQL.Geometry)
  end
end

# For the migrations.
GeoSQL.init(GeoSQL.Test.PostGIS.Repo, json: Jason, decode_binary: :reference)
