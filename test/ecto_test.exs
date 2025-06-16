defmodule GeoSQL.Ecto.Test do
  use ExUnit.Case, async: true
  import Ecto.Query
  use GeoSQL.MM2
  use GeoSQL.MM3
  use GeoSQL.PostGIS
  use GeoSQL.Common
  use GeoSQL.Test.PostGIS.Helper

  @multipoint_wkb "0106000020E6100000010000000103000000010000000F00000091A1EF7505D521C0F4AD6182E481424072B3CE92FED421C01D483CDAE281424085184FAEF7D421C0CB159111E1814240E1EBD7FBF8D421C0D421F7C8DF814240AD111315FFD421C0FE1F21C0DE81424082A0669908D521C050071118DE814240813C5E700FD521C0954EEF97DE814240DC889FA815D521C0B3382182E08142400148A81817D521C0E620D22BE2814240F1E95BDE19D521C08BD53852E3814240F81699E217D521C05B35D7DCE4814240B287C8D715D521C0336338FEE481424085882FB90FD521C0FEF65484E5814240A53E1E460AD521C09A0EA286E581424091A1EF7505D521C0F4AD6182E4814240"

  defmodule Location do
    use Ecto.Schema

    schema "locations" do
      field(:name, :string)
      field(:geom, GeoSQL.Geometry)
    end
  end

  defmodule Geographies do
    use Ecto.Schema

    schema "geographies" do
      field(:name, :string)
      field(:geom, GeoSQL.Geometry)
    end
  end

  defmodule LocationMulti do
    use Ecto.Schema

    schema "location_multi" do
      field(:name, :string)
      field(:geom, GeoSQL.Geometry)
    end
  end

  test "query multipoint" do
    geom = Geo.WKB.decode!(@multipoint_wkb)

    PostGISRepo.insert(%Location{name: "hello", geom: geom})
    query = from(location in Location, limit: 5, select: location)
    results = PostGISRepo.all(query)

    assert geom == hd(results).geom
  end

  test "query area" do
    geom = Geo.WKB.decode!(@multipoint_wkb)

    PostGISRepo.insert(%Location{name: "hello", geom: geom})

    query = from(location in Location, limit: 5, select: MM2.area(location.geom))
    results = PostGISRepo.all(query)

    assert is_number(hd(results))
  end

  test "query transform" do
    geom = Geo.WKB.decode!(@multipoint_wkb)

    PostGISRepo.insert(%Location{name: "hello", geom: geom})

    query = from(location in Location, limit: 1, select: MM2.transform(location.geom, 3452))
    results = PostGISRepo.one(query)

    assert results.srid == 3452
  end

  test "query distance" do
    geom = Geo.WKB.decode!(@multipoint_wkb)

    PostGISRepo.insert(%Location{name: "hello", geom: geom})

    query = from(location in Location, limit: 5, select: MM2.distance(location.geom, ^geom))
    results = PostGISRepo.one(query)

    assert results == 0
  end

  test "query sphere distance" do
    geom = Geo.WKB.decode!(@multipoint_wkb)

    PostGISRepo.insert(%Location{name: "hello", geom: geom})

    query =
      from(location in Location, limit: 5, select: PostGIS.distance_sphere(location.geom, ^geom))

    results = PostGISRepo.one(query)

    assert results == 0
  end

  test "st_extent" do
    geom = Geo.WKB.decode!(@multipoint_wkb)

    PostGISRepo.insert(%Location{name: "hello", geom: geom})

    query = from(location in Location, select: Common.extent(location.geom, PostGISRepo))

    assert [%Geo.Polygon{coordinates: [coordinates]}] = PostGISRepo.all(query)
    assert length(coordinates) == 5
  end

  test "example" do
    geom = Geo.WKB.decode!(@multipoint_wkb)
    PostGISRepo.insert(%Location{name: "hello", geom: geom})

    defmodule Example do
      import Ecto.Query
      require GeoSQL.MM2
      alias GeoSQL.MM2

      def example_query(geom) do
        from(location in Location, select: MM2.distance(location.geom, ^geom))
      end
    end

    query = Example.example_query(geom)
    results = PostGISRepo.one(query)
    assert results == 0
  end

  test "geography" do
    geom = %Geo.Point{coordinates: {30, -90}, srid: 4326}

    PostGISRepo.insert(%Geographies{name: "hello", geom: geom})
    query = from(location in Geographies, limit: 5, select: location)
    results = PostGISRepo.all(query)

    assert geom == hd(results).geom
  end

  test "cast point" do
    geom = %Geo.Point{coordinates: {30, -90}, srid: 4326}

    PostGISRepo.insert(%Geographies{name: "hello", geom: geom})
    query = from(location in Geographies, limit: 5, select: location)
    results = PostGISRepo.all(query)

    result = hd(results)

    json = Geo.JSON.encode(%Geo.Point{coordinates: {31, -90}, srid: 4326})

    changeset =
      Ecto.Changeset.cast(result, %{title: "Hello", geom: json}, [:name, :geom])
      |> Ecto.Changeset.validate_required([:name, :geom])

    assert changeset.changes == %{geom: %Geo.Point{coordinates: {31, -90}, srid: 4326}}
  end

  test "cast point from map" do
    geom = %Geo.Point{coordinates: {30, -90}, srid: 4326}

    PostGISRepo.insert(%Geographies{name: "hello", geom: geom})
    query = from(location in Geographies, limit: 5, select: location)
    results = PostGISRepo.all(query)

    result = hd(results)

    json = %{
      "type" => "Point",
      "crs" => %{"type" => "name", "properties" => %{"name" => "EPSG:4326"}},
      "coordinates" => [31, -90]
    }

    changeset =
      Ecto.Changeset.cast(result, %{title: "Hello", geom: json}, [:name, :geom])
      |> Ecto.Changeset.validate_required([:name, :geom])

    assert changeset.changes == %{geom: %Geo.Point{coordinates: {31, -90}, srid: 4326}}
  end

  test "order by distance" do
    geom1 = %Geo.Point{coordinates: {30, -90}, srid: 4326}
    geom2 = %Geo.Point{coordinates: {30, -91}, srid: 4326}
    geom3 = %Geo.Point{coordinates: {60, -91}, srid: 4326}

    PostGISRepo.insert(%Geographies{name: "there", geom: geom2})
    PostGISRepo.insert(%Geographies{name: "here", geom: geom1})
    PostGISRepo.insert(%Geographies{name: "way over there", geom: geom3})

    query =
      from(
        location in Geographies,
        limit: 5,
        select: location,
        order_by: MM3.ThreeD.distance(location.geom, ^geom1)
      )

    assert ["here", "there", "way over there"] ==
             PostGISRepo.all(query)
             |> Enum.map(fn x -> x.name end)
  end

  test "insert multiple geometry types" do
    geom1 = %Geo.Point{coordinates: {30, -90}, srid: 4326}
    geom2 = %Geo.LineString{coordinates: [{30, -90}, {30, -91}], srid: 4326}

    PostGISRepo.insert(%LocationMulti{name: "hello point", geom: geom1})
    PostGISRepo.insert(%LocationMulti{name: "hello line", geom: geom2})
    query = from(location in LocationMulti, select: location)
    [m1, m2] = PostGISRepo.all(query)

    assert m1.geom == geom1
    assert m2.geom == geom2
  end

  describe "st_node" do
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

  describe "is_collection/1" do
    test "returns true for a geometry collection" do
      collection = %Geo.GeometryCollection{
        geometries: [
          %Geo.Point{coordinates: {0, 0}, srid: 4326},
          %Geo.LineString{coordinates: [{0, 0}, {1, 1}], srid: 4326}
        ],
        srid: 4326
      }

      PostGISRepo.insert(%LocationMulti{name: "collection", geom: collection})

      query =
        from(l in LocationMulti,
          where: l.name == "collection",
          select: PostGIS.is_collection(Common.make_valid(l.geom))
        )

      result = PostGISRepo.one(query)
      assert result == true
    end

    test "returns true for a multi-geometry" do
      multi_point = %Geo.MultiPoint{
        coordinates: [{0, 0}, {1, 1}, {2, 2}],
        srid: 4326
      }

      PostGISRepo.insert(%LocationMulti{name: "multi_point", geom: multi_point})

      query =
        from(l in LocationMulti,
          where: l.name == "multi_point",
          select: PostGIS.is_collection(Common.make_valid(l.geom))
        )

      result = PostGISRepo.one(query)
      assert result == true
    end

    test "returns false for a simple geometry" do
      point = %Geo.Point{coordinates: {0, 0}, srid: 4326}
      PostGISRepo.insert(%LocationMulti{name: "point", geom: point})

      query =
        from(l in LocationMulti,
          where: l.name == "point",
          select: PostGIS.is_collection(l.geom)
        )

      result = PostGISRepo.one(query)
      assert result == false
    end
  end

  describe "is_empty/1" do
    test "returns true for an empty geometry" do
      empty_point = %Geo.Point{coordinates: nil, srid: 4326}

      PostGISRepo.insert(%LocationMulti{name: "empty_point", geom: empty_point})

      query =
        from(l in LocationMulti,
          where: l.name == "empty_point",
          select: MM3.is_empty(l.geom)
        )

      result = PostGISRepo.one(query)

      assert result == true
    end

    test "returns false for a non-empty geometry" do
      point = %Geo.Point{coordinates: {0, 0}, srid: 4326}
      PostGISRepo.insert(%LocationMulti{name: "non_empty", geom: point})

      query =
        from(l in LocationMulti,
          where: l.name == "non_empty",
          select: MM3.is_empty(l.geom)
        )

      result = PostGISRepo.one(query)
      assert result == false
    end
  end

  describe "PostGIS.points/1" do
    test "returns multipoint from a linestring" do
      line_coords = [{0.0, 0.0}, {1.0, 1.0}, {2.0, 2.0}]

      line = %Geo.LineString{
        coordinates: line_coords,
        srid: 4326
      }

      PostGISRepo.insert(%LocationMulti{name: "line_for_points", geom: line})

      query =
        from(l in LocationMulti,
          where: l.name == "line_for_points",
          select: PostGIS.points(l.geom)
        )

      result = PostGISRepo.one(query)

      assert %Geo.MultiPoint{} = result

      assert length(result.coordinates) == 3

      assert MapSet.new(line_coords) == MapSet.new(result.coordinates)
    end

    test "returns multipoint from a polygon" do
      polygon_coords = [{0.0, 0.0}, {0.0, 2.0}, {2.0, 2.0}, {2.0, 0.0}, {0.0, 0.0}]

      polygon = %Geo.Polygon{
        coordinates: [polygon_coords],
        srid: 4326
      }

      PostGISRepo.insert(%LocationMulti{name: "polygon_for_points", geom: polygon})

      query =
        from(l in LocationMulti,
          where: l.name == "polygon_for_points",
          select: PostGIS.points(l.geom)
        )

      result = PostGISRepo.one(query)
      assert %Geo.MultiPoint{} = result

      # 5 coordinates expected including the equivalent overlapping start/end points
      assert length(result.coordinates) == 5
      [overlapping_vertex | _rest] = polygon_coords

      assert Enum.count(result.coordinates, fn coord -> coord == overlapping_vertex end) == 2
      assert MapSet.new(polygon_coords) == MapSet.new(result.coordinates)
    end
  end

  describe "PostGIS.dump" do
    test "atomic geometry is returned directly" do
      point = %Geo.Point{
        coordinates: {0.0, 0.0},
        srid: 4326
      }

      PostGISRepo.insert(%LocationMulti{name: "point", geom: point})

      query =
        from(location in LocationMulti,
          where: location.name == "point",
          select: PostGIS.dump(location.geom)
        )

      result = PostGISRepo.one(query)

      assert result == {[], point}
    end

    test "breaks a multipolygon into its constituent polygons" do
      polygon1 = %Geo.Polygon{
        coordinates: [[{0.0, 0.0}, {0.0, 1.0}, {1.0, 1.0}, {1.0, 0.0}, {0.0, 0.0}]],
        srid: 4326
      }

      polygon2 = %Geo.Polygon{
        coordinates: [[{2.0, 2.0}, {2.0, 3.0}, {3.0, 3.0}, {3.0, 2.0}, {2.0, 2.0}]],
        srid: 4326
      }

      PostGISRepo.insert(%LocationMulti{name: "polygon1", geom: polygon1})
      PostGISRepo.insert(%LocationMulti{name: "polygon2", geom: polygon2})

      query =
        from(
          location in LocationMulti,
          where: location.name in ["polygon1", "polygon2"],
          select: PostGIS.dump(Common.collect(location.geom))
        )

      results = PostGISRepo.all(query)
      assert length(results) == 2

      Enum.each(results, fn {_path, geom} ->
        assert %Geo.Polygon{} = geom
      end)

      expected_polygons = MapSet.new([polygon1, polygon2])
      actual_polygons = MapSet.new(Enum.map(results, fn {_path, geom} -> geom end))

      assert MapSet.equal?(expected_polygons, actual_polygons)
    end
  end

  describe "Common.line_merge/2" do
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
