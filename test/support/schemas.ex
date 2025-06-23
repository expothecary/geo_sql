defmodule GeoSQL.Test.Schema.Location do
  use Ecto.Schema

  schema "locations" do
    field(:name, :string)
    field(:geom, GeoSQL.Geometry)
  end
end

defmodule GeoSQL.Test.Schema.Geographies do
  use Ecto.Schema

  schema "geographies" do
    field(:name, :string)
    field(:geom, GeoSQL.Geometry)
  end
end

defmodule GeoSQL.Test.Schema.LocationMulti do
  use Ecto.Schema

  schema "location_multi" do
    field(:name, :string)
    field(:geom, GeoSQL.Geometry)
  end
end

defmodule GeoSQL.Test.Schema.GeoType do
  use Ecto.Schema

  schema "specified_columns" do
    field(:t, :string)
    field(:point, GeoSQL.Geometry.Point)
    field(:linestring, GeoSQL.Geometry.LineString)
  end
end

defmodule GeoSQL.Test.Schema.WrongGeoType do
  use Ecto.Schema

  schema "specified_columns" do
    field(:t, :string)
    field(:linestring, GeoSQL.Geometry.Point)
  end
end
