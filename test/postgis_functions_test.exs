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

      refute Helper.fuzzy_match_geometry(results.regular, results.best_fit)
    end
  end

  describe "PostGIS: collection_homogenize" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: contains_properly" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: d_within" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: d_fully_within" do
    test "untested" do
      # FIXME
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
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: dump_segments" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: dump_rings" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: expand" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: generate_points" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: has_arc" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: has_m" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: has_z" do
    test "untested" do
      # FIXME
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
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: line_to_curve" do
    test "untested" do
      # FIXME
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
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: longest_line" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: make_box_2d" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: make_envelope" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: make_valid" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: mem_union" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: mem_size" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: normalize" do
    test "untested" do
      # FIXME
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
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: remove_irrelevant_points_for_view" do
    test "untested" do
      # FIXME
    end
  end

  describe "PostGIS: remove_small_parts" do
    test "untested" do
      # FIXME
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
