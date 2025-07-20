defmodule GeoSQL.SpatiaLiteFunctions.Test do
  use ExUnit.Case, async: true
  @moduletag :sqlite3

  import Ecto.Query
  use GeoSQL.Common
  use GeoSQL.SpatiaLite
  use GeoSQL.QueryUtils
  use GeoSQL.Test.Helper

  alias GeoSQL.Test.Schema.Geopackage

  describe "Spatialite: as_gpb" do
    test "creates a usable Geopackage-encoded polygon" do
      polygon = Fixtures.polygon()

      query =
        from(g in Geopackage,
          where: g.id == 1,
          select: SpatiaLite.geom_from_gpb(SpatiaLite.as_gpb(^polygon))
        )

      result =
        query
        |> GeopackageRepo.one()
        |> QueryUtils.decode_geometry(GeopackageRepo)

      assert match?(^polygon, result)
    end
  end

  describe "Spatialite: geom_from_gpb" do
    test "returns a Geopackage-encoded polygon" do
      query = from(g in Geopackage, where: g.id == 1, select: SpatiaLite.geom_from_gpb(g.shape))

      result =
        query
        |> GeopackageRepo.one()
        |> QueryUtils.decode_geometry(GeopackageRepo)

      assert match?(%Geometry.MultiPolygon{srid: 26915}, result)
    end
  end

  describe "Spatialite: is_valid_gpb" do
    test "asserts validity" do
      query = from(g in Geopackage, where: g.id == 1, select: SpatiaLite.is_valid_gpb(g.shape))

      result = GeopackageRepo.one(query)

      assert GeopackageRepo.to_boolean(result)
    end
  end
end
