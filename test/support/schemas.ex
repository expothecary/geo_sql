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
    field(:pointz, GeoSQL.Geometry.PointZ)
    field(:linestring, GeoSQL.Geometry.LineString)
    field(:linestringm, GeoSQL.Geometry.LineStringM)
    field(:linestringzm, GeoSQL.Geometry.LineStringZM)
    field(:multipoint, GeoSQL.Geometry.MultiPoint)
    field(:polygon, GeoSQL.Geometry.Polygon)
    field(:polygonm, GeoSQL.Geometry.PolygonM)
    field(:multipolygon, GeoSQL.Geometry.MultiPolygon)
  end
end

defmodule GeoSQL.Test.Schema.WrongGeoType do
  use Ecto.Schema

  schema "specified_columns" do
    field(:t, :string)
    field(:linestring, GeoSQL.Geometry.Point)
  end
end

defmodule GeoSQL.Test.Schema.Geopackage do
  use Ecto.Schema

  @primary_key false
  schema "dnr_wildlife_management_areas_public_facilities_polygons" do
    field(:id, :integer, source: :OBJECTID)
    field(:name, :string)
    field(:shape, GeoSQL.Geometry.Geopackage, source: :Shape)
  end
end
