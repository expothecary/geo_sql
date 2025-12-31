defmodule GeoSQL.PostGISFunctions.Test do
  use ExUnit.Case, async: true
  @moduletag :pgsql

  import Ecto.Query
  use GeoSQL.PostGIS
  use GeoSQL.Common
  use GeoSQL.MM
  use GeoSQL.Test.Helper

  alias GeoSQL.Test.Schema.{GeoType, Location, LocationMulti}

  describe "PostGIS: affine" do
    test "performs an affine transformation with 3D matrix" do
      geom = Fixtures.multipolygon()

      PostGISRepo.insert(%Location{name: "hello", geom: geom})

      query =
        from(location in Location,
          limit: 5,
          select: PostGIS.affine(location.geom, 1, 2, 3, 4, 5, 6, 7, 8, 9, 5, 10, 15)
        )

      results = PostGISRepo.one(query)
      assert %Geometry.MultiPolygon{} = results
    end

    test "performs an affine transformation with 2D mastrix" do
      geom = Fixtures.multipolygon()

      PostGISRepo.insert(%Location{name: "hello", geom: geom})

      query =
        from(location in Location,
          limit: 5,
          select: PostGIS.affine(location.geom, 1, 2, 3, 4, 6.7, 8.9)
        )

      results = PostGISRepo.one(query)
      assert %Geometry.MultiPolygon{} = results
    end
  end

  describe "PostGIS: angle" do
    test "returns the angle between two lines" do
      line2 = Fixtures.linestring()
      line1 = Fixtures.linestring(:intersects)

      PostGISRepo.insert(%Location{name: "hello", geom: line1})

      query =
        from(location in Location,
          select: PostGIS.angle(location.geom, ^line2)
        )

      results = PostGISRepo.one(query)
      assert is_number(results)
    end

    test "returns the angle between two vectors defined by four points" do
      multipoint = Fixtures.multipoint(:two_vector)

      PostGISRepo.insert(%Location{name: "hello", geom: multipoint})

      query =
        from(l in Location,
          select:
            PostGIS.angle(
              MM.geometry_n(l.geom, 1),
              MM.geometry_n(l.geom, 2),
              MM.geometry_n(l.geom, 3),
              MM.geometry_n(l.geom, 4)
            )
        )

      results = PostGISRepo.one(query)
      assert is_number(results)
    end

    test "returns the angle between two vectors defined by a shared point and two unique points" do
      multipoint = Fixtures.multipoint(:two_vector)

      PostGISRepo.insert(%Location{name: "hello", geom: multipoint})

      query =
        from(l in Location,
          select:
            PostGIS.angle(
              MM.geometry_n(l.geom, 1),
              MM.geometry_n(l.geom, 2),
              MM.geometry_n(l.geom, 3)
            )
        )

      results = PostGISRepo.one(query)
      assert is_number(results)
    end
  end

  describe "PostGIS: bounding_diagonal" do
    test "returns a distance" do
      geom = Fixtures.polygon()

      PostGISRepo.insert(%Location{name: "hello", geom: geom})

      query =
        from(location in Location,
          select: %{
            regular: PostGIS.bounding_diagonal(location.geom),
            best_fit: PostGIS.bounding_diagonal(location.geom, true)
          }
        )

      results = PostGISRepo.one(query)

      srid = geom.srid

      assert %{
               regular: %Geometry.LineString{srid: ^srid},
               best_fit: %Geometry.LineString{srid: ^srid}
             } = results
    end
  end

  describe "PostGIS: collection_homogenize" do
    test "works on a collection" do
      collection = Fixtures.geometry_collection()

      PostGISRepo.insert(%LocationMulti{name: "collection", geom: collection})

      query =
        from(l in LocationMulti,
          where: l.name == "collection",
          select: PostGIS.collection_homogenize(Common.make_valid(l.geom))
        )

      result = PostGISRepo.one(query)
      assert %Geometry.GeometryCollection{} = result
    end
  end

  describe "PostGIS: contains_properly" do
    test "works with two geometries" do
      line = Fixtures.polygon()
      point = Fixtures.point()

      PostGISRepo.insert(%GeoType{t: "hello", polygon: line, point: point})

      query =
        from(location in GeoType,
          select: PostGIS.contains_properly(location.polygon, location.point)
        )

      result = PostGISRepo.one(query)

      assert result === false
    end

    test "works with two geometries without indixes" do
      line = Fixtures.polygon()
      point = Fixtures.point()

      PostGISRepo.insert(%GeoType{t: "hello", polygon: line, point: point})

      query =
        from(location in GeoType,
          select: PostGIS.contains_properly(location.polygon, location.point, :without_indexes)
        )

      result = PostGISRepo.one(query)

      assert result === false
    end
  end

  describe "PostGIS: d_within" do
    test "using the geometry srid" do
      line = Fixtures.polygon()
      point = Fixtures.point()

      PostGISRepo.insert(%GeoType{t: "hello", polygon: line, point: point})

      query =
        from(location in GeoType,
          select: PostGIS.d_within(location.polygon, location.point, 10)
        )

      result = PostGISRepo.one(query)

      assert result === false
    end

    test "on the spheroid" do
      line = Fixtures.polygon()
      point = Fixtures.point()

      PostGISRepo.insert(%GeoType{t: "hello", polygon: line, point: point})

      query =
        from(location in GeoType,
          select: PostGIS.d_within(location.polygon, location.point, 10, true)
        )

      result = PostGISRepo.one(query)

      assert result === false
    end
  end

  describe "PostGIS: d_fully_within" do
    test "untested" do
      line = Fixtures.polygon()
      point = Fixtures.point()

      PostGISRepo.insert(%GeoType{t: "hello", polygon: line, point: point})

      query =
        from(location in GeoType,
          select: PostGIS.d_fully_within(location.polygon, location.point, 10)
        )

      result = PostGISRepo.one(query)

      assert result === false
    end
  end

  describe "PostGIS: distance_sphere" do
    test "returns a distance" do
      geom = Fixtures.multipolygon()

      PostGISRepo.insert(%Location{name: "hello", geom: geom})

      query =
        from(location in Location,
          limit: 5,
          select: PostGIS.distance_sphere(location.geom, ^geom)
        )

      results = PostGISRepo.one(query)

      assert results == 0
    end
  end

  describe "PostGIS: dump" do
    test "atomic geometry is returned directly" do
      point = %Geometry.Point{
        coordinates: [0.0, 0.0],
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
      polygon1 = %Geometry.Polygon{
        rings: [[[0.0, 0.0], [0.0, 1.0], [1.0, 1.0], [1.0, 0.0], [0.0, 0.0]]],
        srid: 4326
      }

      polygon2 = %Geometry.Polygon{
        rings: [[[2.0, 2.0], [2.0, 3.0], [3.0, 3.0], [3.0, 2.0], [2.0, 2.0]]],
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
        assert %Geometry.Polygon{} = geom
      end)

      expected_polygons = MapSet.new([polygon1, polygon2])
      actual_polygons = MapSet.new(Enum.map(results, fn {_path, geom} -> geom end))

      assert MapSet.equal?(expected_polygons, actual_polygons)
    end
  end

  describe "PostGIS: dump_points" do
    test "Unrolls the points out of a multipolygon" do
      geom = Fixtures.multipolygon()

      PostGISRepo.insert(%Location{name: "polygon", geom: geom})

      query =
        from(location in Location,
          select: PostGIS.dump_points(location.geom)
        )

      results = PostGISRepo.all(query)

      assert {[1, 1, 1], %Geometry.Point{}} = Enum.at(results, 0)
      assert 15 == Enum.count(results)
    end
  end

  describe "PostGIS: dump_segments" do
    test "Unrolls the segments out of a multipolygon" do
      geom = Fixtures.multipolygon()

      PostGISRepo.insert(%Location{name: "polygon", geom: geom})

      query =
        from(location in Location,
          select: PostGIS.dump_segments(location.geom)
        )

      results = PostGISRepo.all(query)

      assert {[1, 1, 1], %Geometry.LineString{}} = Enum.at(results, 0)
      assert 14 == Enum.count(results)
    end
  end

  describe "PostGIS: dump_rings" do
    test "untested" do
      geom = Fixtures.polygon()

      PostGISRepo.insert(%Location{name: "polygon", geom: geom})

      query =
        from(location in Location,
          select: PostGIS.dump_rings(location.geom)
        )

      results = PostGISRepo.all(query)

      assert {[0], %Geometry.Polygon{}} = Enum.at(results, 0)
      assert 1 == Enum.count(results)
    end
  end

  describe "PostGIS: expand" do
    test "expands geomtry with dx/dy" do
      geom = Fixtures.polygon()

      PostGISRepo.insert(%Location{name: "hello", geom: geom})

      query =
        from(location in Location,
          select: PostGIS.expand(location.geom, 10, 100)
        )

      assert [%Geometry.Polygon{rings: [ring]}] = PostGISRepo.all(query)

      assert length(ring) == 5
    end

    test "expands geomtry with dx/dy/dz" do
      geom = Fixtures.polygon()

      PostGISRepo.insert(%Location{name: "hello", geom: geom})

      query =
        from(location in Location,
          select: PostGIS.expand(location.geom, 10, 50, 100)
        )

      assert [%Geometry.Polygon{rings: [ring]}] = PostGISRepo.all(query)

      assert length(ring) == 5
    end

    test "expands geomtry with dx/dy/dz/dm" do
      geom = Fixtures.polygon()

      PostGISRepo.insert(%Location{name: "hello", geom: geom})

      query =
        from(location in Location,
          select: PostGIS.expand(location.geom, 10, 100, 0, 1000)
        )

      assert [%Geometry.Polygon{rings: [ring]}] = PostGISRepo.all(query)

      assert length(ring) == 5
    end
  end

  describe "PostGIS: generate_points" do
    test "generates points with a polygon" do
      geom = Fixtures.polygon()

      PostGISRepo.insert(%Location{name: "polygon", geom: geom})

      query =
        from(location in Location,
          select: PostGIS.generate_points(location.geom, 5)
        )

      results = PostGISRepo.one(query)

      assert %Geometry.MultiPoint{} = results
    end

    test "generates points with a polygon and a seed" do
      geom = Fixtures.polygon()

      PostGISRepo.insert(%Location{name: "polygon", geom: geom})

      query =
        from(location in Location,
          select: PostGIS.generate_points(location.geom, 5, 1337)
        )

      results = PostGISRepo.one(query)

      assert %Geometry.MultiPoint{} = results
    end
  end

  describe "PostGIS: has_arc" do
    test "detects if a geometry has an arc" do
      geom = Fixtures.polygon()

      PostGISRepo.insert(%Location{name: "polygon", geom: geom})

      query =
        from(location in Location,
          select: PostGIS.has_arc(location.geom)
        )

      results = PostGISRepo.one(query)

      assert results === false
    end
  end

  describe "PostGIS: has_m" do
    test "detects geometry with measures" do
      geom = Fixtures.point(:m)

      PostGISRepo.insert(%Location{name: "pointm", geom: geom})

      query =
        from(location in Location,
          select: PostGIS.has_m(location.geom)
        )

      results = PostGISRepo.one(query)

      assert results === true
    end
  end

  describe "PostGIS: has_z" do
    test "detects 3D geometry" do
      geom = Fixtures.point(:z)

      PostGISRepo.insert(%Location{name: "pointz", geom: geom})

      query =
        from(location in Location,
          select: PostGIS.has_z(location.geom)
        )

      results = PostGISRepo.one(query)

      assert results === true
    end
  end

  describe "PostGIS: is_collection" do
    test "returns true for a geometry collection" do
      collection = %Geometry.GeometryCollection{
        geometries: [
          %Geometry.Point{coordinates: [0, 0], srid: 4326},
          %Geometry.LineString{path: [[0, 0], [1, 1]], srid: 4326}
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
      multi_point = %Geometry.MultiPoint{
        points: [[0, 0], [1, 1], [2, 2]],
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
      point = %Geometry.Point{coordinates: [0, 0], srid: 4326}
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

  describe "PostGIS: line_crossing_direction" do
    test "detects crossing directions" do
      lineA = Fixtures.linestring()
      lineB = Fixtures.linestring(:intersects)

      PostGISRepo.insert(%LocationMulti{name: "line", geom: lineA})

      query =
        from(l in LocationMulti,
          select: PostGIS.line_crossing_direction(l.geom, ^lineB)
        )

      result = PostGISRepo.one(query)
      assert PostGIS.crossing_direction(result) == :left
    end
  end

  describe "PostGIS: line_to_curve" do
    test "operates on a line" do
      line = Fixtures.linestring()

      PostGISRepo.insert(%LocationMulti{name: "line", geom: line})

      query =
        from(l in LocationMulti,
          select: PostGIS.line_to_curve(l.geom)
        )

      result = PostGISRepo.one(query)
      assert %Geometry.LineString{} = result
    end
  end

  describe "PostGIS: locate_along" do
    test "returns matching points from a PolygonM past an offset" do
      linestringzm = Fixtures.linestring(:zm)

      PostGISRepo.insert(%GeoType{linestringzm: linestringzm})

      result =
        from(g in GeoType,
          select: PostGIS.locate_along(g.linestringzm, 10, 2)
        )
        |> PostGISRepo.one()

      assert %Geometry.MultiPointZM{} = result
      assert Enum.count(result.points) == 5
    end
  end

  describe "PostGIS: locate_between" do
    test "returns matching points from a PolygonM past an offset" do
      linestringzm = Fixtures.linestring(:zm)

      PostGISRepo.insert(%GeoType{linestringzm: linestringzm})

      result =
        from(g in GeoType,
          select: PostGIS.locate_between(g.linestringzm, 10, 20, 0.5)
        )
        |> PostGISRepo.one()

      assert %Geometry.MultiLineString{} = result
      assert Enum.count(result.line_strings) == 2
    end
  end

  describe "PostGIS: locate_between_elevations" do
    test "returns matching points from a PolygonZM between to elevations" do
      linestringzm = Fixtures.linestring(:zm)

      PostGISRepo.insert(%GeoType{linestringzm: linestringzm})

      result =
        from(g in GeoType,
          select: PostGIS.locate_between_elevations(g.linestringzm, 3, 7)
        )
        |> PostGISRepo.one()

      assert %Geometry.MultiLineStringZM{} = result
      assert Enum.count(result.line_strings) == 1
    end
  end

  describe "PostGIS: longest_line" do
    test "returns a line" do
      linestring = Fixtures.linestring()
      point = Fixtures.point()

      PostGISRepo.insert(%GeoType{linestring: linestring, point: point})

      result =
        from(g in GeoType,
          select: PostGIS.longest_line(g.linestring, g.point)
        )
        |> PostGISRepo.one()

      assert %Geometry.LineString{} = result
    end
  end

  describe "PostGIS: make_box_2d" do
    test "returns a polygon" do
      pointA = Fixtures.point()
      pointB = Fixtures.point(:comparison)

      PostGISRepo.insert(%GeoType{point: pointA})

      result =
        from(g in GeoType,
          select: PostGIS.make_box_2d(g.point, ^pointB)
        )
        |> PostGISRepo.one()

      assert %GeoSQL.PostGIS.Box2D{} = result
    end
  end

  describe "PostGIS: make_envelope" do
    test "Turns coordiantes into a polygon" do
      PostGISRepo.insert(%GeoType{})

      result =
        from(g in GeoType,
          select: PostGIS.make_envelope(1, 2, 3, 4)
        )
        |> PostGISRepo.one()

      assert %Geometry.Polygon{} = result
    end

    test "Turns coordiantes into a polygon with an srid" do
      PostGISRepo.insert(%GeoType{})

      result =
        from(g in GeoType,
          select: PostGIS.make_envelope(1, 2, 3, 4, 5)
        )
        |> PostGISRepo.one()

      assert %Geometry.Polygon{srid: 5} = result
    end
  end

  describe "PostGIS: make_valid" do
    test "makes a polygon valid" do
      polygon = Fixtures.polygon()
      PostGISRepo.insert(%GeoType{polygon: polygon})

      result =
        from(g in GeoType,
          select: PostGIS.make_valid(g.polygon)
        )
        |> PostGISRepo.one()

      assert %Geometry.Polygon{} = result
    end

    test "makes a polygon valid with params" do
      polygon = Fixtures.polygon()
      params = "method=structure keepcollapsed=true"
      PostGISRepo.insert(%GeoType{polygon: polygon})

      result =
        from(g in GeoType,
          select: PostGIS.make_valid(g.polygon, ^params)
        )
        |> PostGISRepo.one()

      assert %Geometry.Polygon{} = result
    end
  end

  describe "PostGIS: mem_union" do
    test "unions lines into a multiline" do
      line = Fixtures.linestring()
      PostGISRepo.insert(%LocationMulti{name: "a", geom: line})
      ring = Fixtures.linestring(:ring)
      PostGISRepo.insert(%LocationMulti{name: "a", geom: ring})

      query =
        from(l in LocationMulti,
          select: PostGIS.mem_union(l.geom)
        )

      result = PostGISRepo.one(query)

      assert %Geometry.MultiLineString{} = result
    end
  end

  describe "PostGIS: mem_size" do
    test "returns the memory size of a line" do
      line = Fixtures.linestring()
      PostGISRepo.insert(%LocationMulti{name: "line", geom: line})

      query =
        from(l in LocationMulti,
          select: PostGIS.mem_size(l.geom)
        )

      result = PostGISRepo.one(query)

      assert is_integer(result) and result > 0
    end
  end

  describe "PostGIS: normalize" do
    test "works on a polygon" do
      polygon = Fixtures.polygon()
      PostGISRepo.insert(%GeoType{polygon: polygon})

      result =
        from(g in GeoType,
          select: PostGIS.normalize(g.polygon)
        )
        |> PostGISRepo.one()

      assert %Geometry.Polygon{} = result
    end
  end

  describe "PostGIS: points/1" do
    test "returns multipoint from a linestring" do
      path = [[0.0, 0.0], [1.0, 1.0], [2.0, 2.0]]

      line = %Geometry.LineString{path: path, srid: 4326}

      PostGISRepo.insert(%LocationMulti{name: "line_for_points", geom: line})

      query =
        from(l in LocationMulti,
          where: l.name == "line_for_points",
          select: PostGIS.points(l.geom)
        )

      result = PostGISRepo.one(query)

      assert %Geometry.MultiPoint{} = result

      assert length(result.points) == 3

      assert MapSet.new(path) == MapSet.new(result.points)
    end

    test "returns multipoint from a polygon" do
      polygon_coords = [[0.0, 0.0], [0.0, 2.0], [2.0, 2.0], [2.0, 0.0], [0.0, 0.0]]

      polygon = %Geometry.Polygon{
        rings: [polygon_coords],
        srid: 4326
      }

      PostGISRepo.insert(%LocationMulti{name: "polygon_for_points", geom: polygon})

      query =
        from(l in LocationMulti,
          where: l.name == "polygon_for_points",
          select: PostGIS.points(l.geom)
        )

      result = PostGISRepo.one(query)
      assert %Geometry.MultiPoint{} = result

      # 5 coordinates expected including the equivalent overlapping start/end points
      assert length(result.points) == 5
      [overlapping_vertex | _rest] = polygon_coords

      assert Enum.count(result.points, fn point -> point == overlapping_vertex end) == 2
      assert MapSet.new(polygon_coords) == MapSet.new(result.points)
    end
  end

  describe "PostGIS: quantize_coordinates" do
    test "works on a line" do
      line = Fixtures.linestring()
      PostGISRepo.insert(%LocationMulti{name: "line", geom: line})

      query =
        from(l in LocationMulti,
          select: PostGIS.quantize_coordinates(l.geom, x: 1, y: 0, z: 0, m: 0)
        )

      result = PostGISRepo.one(query)

      assert %Geometry.LineString{} = result
    end
  end

  describe "PostGIS: remove_irrelevant_points_for_view" do
    test "works on a line" do
      line = Fixtures.linestring()
      PostGISRepo.insert(%LocationMulti{name: "line", geom: line})

      query =
        from(l in LocationMulti,
          select:
            PostGIS.remove_irrelevant_points_for_view(
              l.geom,
              ^%PostGIS.Box2D{
                xmin: 10,
                ymin: 50,
                xmax: 60,
                ymax: 60
              }
            )
        )

      result = PostGISRepo.one(query)

      assert %Geometry.LineString{} = result
    end
  end

  describe "PostGIS: remove_small_parts" do
    test "works on a line" do
      line = Fixtures.linestring()
      PostGISRepo.insert(%LocationMulti{name: "line", geom: line})

      query =
        from(l in LocationMulti,
          select: PostGIS.remove_small_parts(l.geom, 5, 5)
        )

      result = PostGISRepo.one(query)

      assert %Geometry.LineString{} = result
    end
  end

  describe "PostGIS: rotate" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: rotate_x" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: rotate_y" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: rotate_z" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: scale" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: scroll" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: summary" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: swap_ordinates" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: trans_scale" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: wrap_x" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: zm_flag" do
    test "untested" do
      # FIXME
    end
  end
end
