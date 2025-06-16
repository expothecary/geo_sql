defmodule GeoSQL.CommonFunctions.Test do
  use ExUnit.Case, async: true
  import Ecto.Query
  use GeoSQL.MM2
  use GeoSQL.MM3
  use GeoSQL.PostGIS
  use GeoSQL.Common
  use GeoSQL.Test.PostGIS.Helper
  alias GeoSQL.Test.PostGIS.Helper

  alias TestSchema.{Location, LocationMulti}

  describe "extent" do
    test "extent" do
      geom = Geo.WKB.decode!(Helper.multipoint_wkb())

      PostGISRepo.insert(%Location{name: "hello", geom: geom})

      query = from(location in Location, select: Common.extent(location.geom, PostGISRepo))

      assert [%Geo.Polygon{coordinates: [coordinates]}] = PostGISRepo.all(query)
      assert length(coordinates) == 5
    end
  end

  describe "node" do
    test "self-intersecting linestring" do
      coordinates = [{0, 0, 0}, {2, 2, 2}, {0, 2, 0}, {2, 0, 2}]
      cross_point = {1, 1, 1}

      # Create a self-intersecting linestring (crossing at point {1, 1, 1})
      linestring = %Geo.LineStringZ{
        coordinates: coordinates,
        srid: 4326
      }

      PostGISRepo.insert(%LocationMulti{name: "intersecting lines", geom: linestring})

      query =
        from(
          location in LocationMulti,
          select: Common.node(location.geom)
        )

      result = PostGISRepo.one(query)

      assert %Geo.MultiLineStringZ{} = result

      assert result.coordinates == [
               [Enum.at(coordinates, 0), cross_point],
               [cross_point, Enum.at(coordinates, 1), Enum.at(coordinates, 2), cross_point],
               [cross_point, Enum.at(coordinates, 3)]
             ]
    end

    test "intersecting multilinestring" do
      coordinates1 = [{0, 0, 0}, {2, 2, 2}]
      coordinates2 = [{0, 2, 0}, {2, 0, 2}]
      cross_point = {1, 1, 1}

      # Create a multilinestring that intersects (crossing at point {1, 1, 1})
      linestring = %Geo.MultiLineStringZ{
        coordinates: [
          coordinates1,
          coordinates2
        ],
        srid: 4326
      }

      PostGISRepo.insert(%LocationMulti{name: "intersecting lines", geom: linestring})

      query =
        from(
          location in LocationMulti,
          select: Common.node(location.geom)
        )

      result = PostGISRepo.one(query)

      assert %Geo.MultiLineStringZ{} = result

      assert result.coordinates == [
               [Enum.at(coordinates1, 0), cross_point],
               [Enum.at(coordinates2, 0), cross_point],
               [cross_point, Enum.at(coordinates1, 1)],
               [cross_point, Enum.at(coordinates2, 1)]
             ]
    end
  end

  describe "line_merge/2" do
    test "lines with opposite directions not merged if directed is true" do
      multiline = %Geo.MultiLineString{
        coordinates: [
          [{60, 30}, {10, 70}],
          [{120, 50}, {60, 30}],
          [{120, 50}, {180, 30}]
        ],
        srid: 4326
      }

      PostGISRepo.insert(%LocationMulti{name: "lines with direction", geom: multiline})

      query =
        from(
          location in LocationMulti,
          where: location.name == "lines with direction",
          select: Common.line_merge(location.geom, true)
        )

      result = PostGISRepo.one(query)

      # Verify the result is still a MultiLineString with only 2 lines merged

      assert %Geo.MultiLineString{} = result

      assert length(result.coordinates) == 2

      expected_linestrings = [
        [{120, 50}, {60, 30}, {10, 70}],
        [{120, 50}, {180, 30}]
      ]

      sorted_result = Enum.sort_by(result.coordinates, fn linestring -> hd(linestring) end)

      sorted_expected = Enum.sort_by(expected_linestrings, fn linestring -> hd(linestring) end)

      assert sorted_result == sorted_expected
    end

    test "lines with opposite directions merged if directed is false" do
      multiline = %Geo.MultiLineString{
        coordinates: [
          [{60, 30}, {10, 70}],
          [{120, 50}, {60, 30}],
          [{120, 50}, {180, 30}]
        ],
        srid: 4326
      }

      PostGISRepo.insert(%LocationMulti{name: "lines with direction", geom: multiline})

      query =
        from(
          location in LocationMulti,
          where: location.name == "lines with direction",
          select: Common.line_merge(location.geom, false)
        )

      result = PostGISRepo.one(query)

      assert %Geo.LineString{} = result

      assert result.coordinates == [
               {180, 30},
               {120, 50},
               {60, 30},
               {10, 70}
             ]
    end
  end
end
