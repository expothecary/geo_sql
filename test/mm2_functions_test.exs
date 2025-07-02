defmodule GeoSQL.MM2Functions.Test do
  use ExUnit.Case, async: true
  @moduletag :mm2

  import Ecto.Query
  use GeoSQL.MM2
  use GeoSQL.Test.Helper
  use GeoSQL.RepoUtils
  use GeoSQL.QueryUtils
  use GeoSQL.Common

  alias GeoSQL.Test.Schema.{Location, GeoType}

  setup do
    geom = Fixtures.multipolygon()

    for repo <- Helper.repos() do
      repo.insert(%Location{name: "Smallville", geom: geom})
    end

    :ok
  end

  defmodule Example do
    import Ecto.Query
    require GeoSQL.MM2
    alias GeoSQL.MM2

    def example_query(geom) do
      from(location in Location, select: MM2.distance(location.geom, ^geom))
    end
  end

  for repo <- Helper.repos() do
    describe "SQL/MM2: area (#{repo})" do
      test "returns a numeric result" do
        query = from(location in Location, select: MM2.area(location.geom))
        result = unquote(repo).all(query)

        assert is_number(hd(result))
      end
    end

    describe "SQL/MM2: as_binary (#{repo})" do
      test "returns a binary representation of the geometry" do
        query = from(location in Location, select: MM2.as_binary(location.geom))

        result = unquote(repo).all(query)

        expected = [
          <<1, 6, 0, 0, 0, 1, 0, 0, 0, 1, 3, 0, 0, 0, 1, 0, 0, 0, 15, 0, 0, 0, 145, 161, 239, 117,
            5, 213, 33, 192, 244, 173, 97, 130, 228, 129, 66, 64, 114, 179, 206, 146, 254, 212,
            33, 192, 29, 72, 60, 218, 226, 129, 66, 64, 133, 24, 79, 174, 247, 212, 33, 192, 203,
            21, 145, 17, 225, 129, 66, 64, 225, 235, 215, 251, 248, 212, 33, 192, 212, 33, 247,
            200, 223, 129, 66, 64, 173, 17, 19, 21, 255, 212, 33, 192, 254, 31, 33, 192, 222, 129,
            66, 64, 130, 160, 102, 153, 8, 213, 33, 192, 80, 7, 17, 24, 222, 129, 66, 64, 129, 60,
            94, 112, 15, 213, 33, 192, 149, 78, 239, 151, 222, 129, 66, 64, 220, 136, 159, 168,
            21, 213, 33, 192, 179, 56, 33, 130, 224, 129, 66, 64, 1, 72, 168, 24, 23, 213, 33,
            192, 230, 32, 210, 43, 226, 129, 66, 64, 241, 233, 91, 222, 25, 213, 33, 192, 139,
            213, 56, 82, 227, 129, 66, 64, 248, 22, 153, 226, 23, 213, 33, 192, 91, 53, 215, 220,
            228, 129, 66, 64, 178, 135, 200, 215, 21, 213, 33, 192, 51, 99, 56, 254, 228, 129, 66,
            64, 133, 136, 47, 185, 15, 213, 33, 192, 254, 246, 84, 132, 229, 129, 66, 64, 165, 62,
            30, 70, 10, 213, 33, 192, 154, 14, 162, 134, 229, 129, 66, 64, 145, 161, 239, 117, 5,
            213, 33, 192, 244, 173, 97, 130, 228, 129, 66, 64>>
        ]

        assert result === expected
      end
    end

    describe "SQL/MM2: as_text (#{repo})" do
      as_text_is_ewkt = [GeoSQL.Test.PostGIS.Repo]

      test "returns as text version" do
        result =
          from(location in Location,
            limit: 1,
            select: MM2.as_text(location.geom)
          )
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        expected =
          if Enum.member?(unquote(as_text_is_ewkt), unquote(repo)) do
            Fixtures.multipolygon()
          else
            Fixtures.multipolygon() |> Map.put(:srid, 0)
          end

        assert Helper.fuzzy_match_geometry(
                 expected.polygons,
                 Map.get(Geometry.from_ewkt!(result), :polygons)
               )
      end

      test "equality checks with as text" do
        geom = Fixtures.multipolygon()
        comparison = Fixtures.multipolygon(:comparison)

        result =
          from(location in Location,
            limit: 1,
            select: %{
              different:
                MM2.as_text(location.geom) ==
                  MM2.as_text(QueryUtils.cast_to_geometry(^comparison, unquote(repo))),
              same:
                MM2.as_text(location.geom) ==
                  MM2.as_text(QueryUtils.cast_to_geometry(^geom, unquote(repo)))
            }
          )
          |> unquote(repo).one()

        assert match?(
                 %{same: true, different: false},
                 result
               )
      end
    end

    describe "SQL/MM2: boundary (#{repo})" do
      test "returns a LineString or MultiLinestring from geometry" do
        query = from(location in Location, limit: 1, select: MM2.boundary(location.geom))

        [result] =
          unquote(repo).all(query)
          |> GeoSQL.decode_geometry(unquote(repo))

        assert Helper.is_a(result, [Geometry.LineString, Geometry.MultiLineString])

        case result do
          %Geometry.LineString{path: path} ->
            assert is_list(path)

          %Geometry.MultiLineString{line_strings: line_strings} ->
            assert is_list(line_strings)

          %x{} ->
            flunk("Got #{x}")
        end
      end
    end

    describe "SQL/MM2: buffer (#{repo})" do
      test "returns a polygon with a radius" do
        query = from(location in Location, select: MM2.buffer(location.geom, 10))

        [result | _] =
          unquote(repo).all(query)
          |> GeoSQL.decode_geometry(unquote(repo))

        assert match?(
                 %Geometry.Polygon{rings: _coordinates, srid: 4326},
                 result
               )

        assert is_list(result.rings)
      end

      test "returns a polygon with a radius and quadrant arg" do
        query = from(location in Location, select: MM2.buffer(location.geom, 10, 8))

        [result | _] =
          unquote(repo).all(query)
          |> GeoSQL.decode_geometry(unquote(repo))

        assert match?(
                 %Geometry.Polygon{srid: 4326, rings: _coordinates},
                 result
               )

        assert is_list(result.rings)
      end
    end

    describe "SQL/MM2: centroid (#{repo})" do
      test "returns a centroid point" do
        query = from(location in Location, select: MM2.centroid(location.geom))
        result = unquote(repo).one(query) |> GeoSQL.decode_geometry(unquote(repo))
        assert match?(%Geometry.Point{}, result)
      end
    end

    describe "SQL/MM2: contains (#{repo})" do
      test "returns true" do
        point = Fixtures.point()
        query = from(location in Location, select: MM2.contains(location.geom, ^point))
        result = unquote(repo).one(query)
        refute unquote(repo).to_boolean(result)
      end
    end

    describe "SQL/MM2: convex_hull (#{repo})" do
      test "returns a polygon" do
        query = from(location in Location, select: MM2.convex_hull(location.geom))
        result = unquote(repo).one(query) |> GeoSQL.decode_geometry(unquote(repo))
        assert match?(%Geometry.Polygon{}, result)
      end
    end

    describe "SQL/MM2: crosses (#{repo})" do
      test "detects crossing" do
        point = %Geometry.Point{coordinates: [8, 10], srid: 4326}
        query = from(location in Location, select: MM2.crosses(location.geom, ^point))
        result = unquote(repo).one(query)
        refute unquote(repo).to_boolean(result)
      end
    end

    describe "SQL/MM2: difference (#{repo})" do
      test "return a polygon" do
        comparison = Fixtures.multipolygon(:comparison)

        query =
          from(location in Location, select: MM2.difference(location.geom, ^comparison))

        result =
          unquote(repo).one(query)
          |> GeoSQL.decode_geometry(unquote(repo))

        assert match?(%Geometry.Polygon{}, result)
      end
    end

    describe "SQL/MM2: dimension (#{repo})" do
      test "returns the correct dimensionality of a geometry" do
        query = from(location in Location, select: MM2.dimension(location.geom))
        result = unquote(repo).one(query)
        assert 2 = result
      end
    end

    describe "SQL/MM2: disjoint (#{repo})" do
      test "determines if two geometries are disjoint" do
        comparison = Fixtures.multipolygon(:comparison)

        query =
          from(location in Location, select: MM2.disjoint(location.geom, ^comparison))

        result = unquote(repo).one(query)
        refute unquote(repo).to_boolean(result)
      end
    end

    describe "SQL/MM2: distance (#{repo})" do
      test "determines the distaince between two geometries" do
        geom = Fixtures.multipolygon()
        query = from(location in Location, select: MM2.distance(location.geom, ^geom))
        result = unquote(repo).one(query)
        assert result == 0
      end
    end

    describe "SQL/MM2: equals (#{repo})" do
      test "determines equality between two geometries" do
        geom = Fixtures.multipolygon()
        query = from(location in Location, select: MM2.distance(location.geom, ^geom))
        result = unquote(repo).one(query)
        assert result == 0
      end
    end

    describe "SQL/MM2: end_point (#{repo})" do
      test "returns the last point of a line" do
        line = Fixtures.linestring()
        expected = %Geometry.Point{coordinates: Enum.at(line.path, -1), srid: line.srid}
        unquote(repo).insert(%GeoType{t: "hello", linestring: line})

        query =
          from(location in GeoType, select: MM2.end_point(location.linestring))

        result =
          unquote(repo).one(query)
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result == expected
      end
    end

    describe "SQL/MM2: envelope (#{repo})" do
      test "returns the enveloper around a geometry" do
        query = from(location in Location, select: MM2.envelope(location.geom))

        result =
          unquote(repo).one(query)
          |> GeoSQL.decode_geometry(unquote(repo))

        assert %Geometry.Polygon{} = result
      end
    end

    describe "SQL/MM2: geometry_n (#{repo})" do
      test "returns the 2nd point of a multpolygon" do
        query =
          from(location in Location, select: MM2.geometry_n(location.geom, 1))

        result =
          unquote(repo).one(query)
          |> GeoSQL.decode_geometry(unquote(repo))

        multipolygon = Fixtures.multipolygon()
        assert result.rings == Enum.at(multipolygon.polygons, 0)
      end

      test "returns nil when requesting a non-extant geometry" do
        query =
          from(location in Location, select: MM2.geometry_n(location.geom, 2))

        result =
          unquote(repo).one(query)
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result == nil
      end
    end

    describe "SQL/MM2: geometry_type (#{repo})" do
      test "tells us the the location geom is a multipolygon" do
        query = from(location in Location, select: MM2.geometry_type(location.geom))

        result =
          unquote(repo).one(query)

        assert GeoSQL.Geometry.from_db_type(result) == Geometry.MultiPolygon
      end
    end

    describe "SQL/MM2: interior_ring_n (#{repo})" do
      test "returns location.geom's inner ring" do
        polygon = Fixtures.polygon(:donut)
        #         IO.puts(Geometry.to_ewkt(polygon))
        query = from(location in Location, select: MM2.interior_ring_n(^polygon, 1))

        result =
          unquote(repo).one(query)
          |> GeoSQL.decode_geometry(unquote(repo))

        assert %Geometry.LineString{} = result
      end
    end

    describe "SQL/MM2: intersection (#{repo})" do
      test "returns intersecton point" do
        lineA = Fixtures.linestring()
        lineB = Fixtures.linestring(:intersects)

        unquote(repo).insert(%GeoType{t: "hello", linestring: lineA})

        query =
          from(location in GeoType,
            select: MM2.intersection(location.linestring, ^lineB)
          )

        result =
          unquote(repo).one(query)
          |> GeoSQL.decode_geometry(unquote(repo))

        assert %Geometry.Point{} = result
      end
    end

    describe "SQL/MM2: iontersects (#{repo})" do
      test "can detect intersections" do
        lineA = Fixtures.linestring()
        lineB = Fixtures.linestring(:intersects)

        unquote(repo).insert(%GeoType{t: "hello", linestring: lineA})

        query =
          from(location in GeoType,
            select: MM2.intersects(location.linestring, ^lineB)
          )

        result =
          unquote(repo).one(query)
          |> unquote(repo).to_boolean()

        assert result
      end
    end

    describe "SQL/MM2: is_closed (#{repo})" do
      test "can detect closure of geometry" do
        lineA = Fixtures.linestring()
        unquote(repo).insert(%GeoType{t: "hello", linestring: lineA})

        query =
          from(location in GeoType,
            select: MM2.is_closed(location.linestring)
          )

        result =
          unquote(repo).one(query)
          |> unquote(repo).to_boolean()

        refute result
      end
    end

    describe "SQL/MM2: is_ring (#{repo})" do
      test "can detect rings, and not rings" do
        line = Fixtures.linestring()
        polygon = Fixtures.polygon()
        unquote(repo).insert(%GeoType{t: "hello", linestring: line, polygon: polygon})

        query =
          from(location in GeoType,
            select: %{
              line: MM2.is_closed(location.linestring),
              polygon: MM2.is_closed(location.polygon)
            }
          )

        result =
          unquote(repo).one(query)
          |> then(fn result ->
            %{
              line: unquote(repo).to_boolean(result.line),
              polygon: unquote(repo).to_boolean(result.polygon)
            }
          end)

        if unquote(repo) == GeoSQL.Test.SQLite3.Repo do
          # Spatialite appears to be buggy here and returns 0 (false) for a polygon ring
          assert match?(%{line: false}, result)
          refute match?(%{polygon: true}, result)
        else
          assert match?(%{line: false, polygon: true}, result)
        end
      end
    end

    describe "SQL/MM2: is_simple (#{repo})" do
      test "detects simplicity" do
        line = Fixtures.linestring(:self_intersecting)
        polygon = Fixtures.polygon()
        unquote(repo).insert(%GeoType{t: "hello", linestring: line, polygon: polygon})

        query =
          from(location in GeoType,
            select: %{
              line: MM2.is_simple(location.linestring),
              polygon: MM2.is_simple(location.polygon)
            }
          )

        result =
          unquote(repo).one(query)
          |> then(fn result ->
            %{
              line: unquote(repo).to_boolean(result.line),
              polygon: unquote(repo).to_boolean(result.polygon)
            }
          end)

        assert match?(%{line: false, polygon: true}, result)
      end
    end

    describe "SQL/MM2: is_valid (#{repo})" do
      test "differentiates valid from invalid geometries" do
        line = Fixtures.linestring()
        polygon = Fixtures.polygon()
        invalid_polygon = Fixtures.polygon(:invalid)
        unquote(repo).insert(%GeoType{t: "hello", linestring: line, polygon: polygon})

        query =
          from(location in GeoType,
            select: %{
              line: MM2.is_valid(location.linestring),
              polygon: MM2.is_valid(location.polygon),
              valid: MM2.is_valid(^invalid_polygon)
            }
          )

        result =
          unquote(repo).one(query)
          |> then(fn result ->
            %{
              line: unquote(repo).to_boolean(result.line),
              polygon: unquote(repo).to_boolean(result.polygon),
              valid: unquote(repo).to_boolean(result.valid)
            }
          end)

        assert match?(%{line: true, polygon: true, valid: false}, result)
      end
    end

    describe "SQL/MM2: length (#{repo})" do
      test "can measure a line" do
        line = Fixtures.linestring()
        unquote(repo).insert(%GeoType{t: "hello", linestring: line})

        query =
          from(location in GeoType,
            select: MM2.length(location.linestring)
          )

        result =
          unquote(repo).one(query)

        assert result == 1.0
      end
    end

    describe "SQL/MM2: line_from_text (#{repo})" do
      test "creates a line from WKT" do
        line = Fixtures.linestring()
        wkt = Geometry.to_wkt(line)
        unquote(repo).insert(%GeoType{t: "hello", linestring: line})

        query =
          from(location in GeoType,
            select: location.linestring == MM2.line_from_text(^wkt, ^line.srid)
          )

        assert unquote(repo).one(query) == true
      end
    end

    describe "SQL/MM2: linestring_from_wkb (#{repo})" do
      test "creates a linestring from WKB" do
        line = Fixtures.linestring()

        wkb = Geometry.to_wkb(line)
        unquote(repo).insert(%GeoType{t: "hello", linestring: line})

        from(location in GeoType)
        |> unquote(repo).all()

        query =
          from(location in GeoType,
            select:
              location.linestring ==
                MM2.linestring_from_wkb(^QueryUtils.wrap_wkb(wkb, unquote(repo)), ^line.srid)
          )

        result =
          unquote(repo).one(query)

        assert result == true
      end
    end

    describe "SQL/MM2: m (#{repo})" do
      test "returns the m value from a geometry" do
        point = Fixtures.point(:m)

        result =
          from(location in Location, select: MM2.m(^point))
          |> unquote(repo).one()

        assert result == 10
      end
    end

    describe "SQL/MM2: m_point_from_text (#{repo})" do
      test "creates a multipoint" do
        geom = Fixtures.multipoint()

        wkt = Geometry.to_wkt(geom)

        result =
          from(location in Location, select: MM2.m_point_from_text(^wkt, ^geom.srid))
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result == geom
      end
    end

    describe "SQL/MM2: m_line_from_text (#{repo})" do
      test "creates a multiline" do
        geom = Fixtures.multilinestring()

        wkt = Geometry.to_wkt(geom)

        result =
          from(location in Location, select: MM2.m_line_from_text(^wkt, ^geom.srid))
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result == geom
      end
    end

    describe "SQL/MM2: m_poly_from_text (#{repo})" do
      test "creates a multipolygon" do
        geom = Fixtures.multipolygon()

        wkt = Geometry.to_wkt(geom)

        result =
          from(location in Location, select: MM2.m_poly_from_text(^wkt, ^geom.srid))
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result == geom
      end
    end

    describe "SQL/MM2: geom_collection_from_text (#{repo})" do
      test "creates a geometry collection" do
        geom = Fixtures.geometrycollection()

        wkt = Geometry.to_wkt(geom)

        result =
          from(location in Location, select: MM2.geom_collection_from_text(^wkt, ^geom.srid))
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert match?(^result, geom)
      end
    end

    describe "SQL/MM2: geom_from_wkb (#{repo})" do
      test "creates a geometry" do
        geom = Fixtures.multipolygon()
        wkb = Geometry.to_wkb(geom)

        result =
          from(location in Location,
            select: MM2.geom_from_wkb(^QueryUtils.wrap_wkb(wkb, unquote(repo)), ^geom.srid)
          )
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert match?(^result, geom)
      end
    end

    describe "SQL/MM2: num_geometries (#{repo})" do
      test "returns a count" do
        result =
          from(location in Location, select: MM2.num_geometries(location.geom))
          |> unquote(repo).one()

        assert result == 1
      end
    end

    describe "SQL/MM2: num_interior_rings (#{repo})" do
      test "returns a count" do
        polygon = Fixtures.polygon(:donut)
        unquote(repo).insert(%GeoType{t: "hello", polygon: polygon})

        result =
          from(g in GeoType, select: MM2.num_interior_rings(g.polygon))
          |> unquote(repo).one()

        assert result == 2
      end
    end

    describe "SQL/MM2: num_points (#{repo})" do
      test "returns a count" do
        linestring = Fixtures.linestring()
        unquote(repo).insert(%GeoType{t: "hello", linestring: linestring})

        result =
          from(g in GeoType, select: MM2.num_points(g.linestring))
          |> unquote(repo).one()

        assert result == 2
      end
    end

    describe "SQL/MM2: overlaps (#{repo})" do
      test "calculates overlap" do
        linestring = Fixtures.linestring()
        polygon = Fixtures.polygon(:donut)
        unquote(repo).insert(%GeoType{t: "hello", linestring: linestring, polygon: polygon})

        result =
          from(g in GeoType, select: MM2.overlaps(g.linestring, g.polygon))
          |> unquote(repo).one()

        refute unquote(repo).to_boolean(result)
      end
    end

    describe "SQL/MM2: point (#{repo})" do
      test "makes a point from coordinates" do
        point = Fixtures.point()
        [x, y] = point.coordinates

        result =
          from(location in Location, select: MM2.point(^x, ^y))
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result.coordinates == point.coordinates
      end
    end

    describe "SQL/MM2: point_from_text (#{repo})" do
      test "makes a point from WKT" do
        point = Fixtures.point()
        wkt = Geometry.to_wkt(point)

        result =
          from(location in Location, select: MM2.point_from_text(^wkt, ^point.srid))
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result == point
      end
    end

    describe "SQL/MM2: point_from_wkb (#{repo})" do
      test "makes a point from WKB" do
        point = Fixtures.point()
        wkb = Geometry.to_wkb(point)

        result =
          from(location in Location,
            select: MM2.point_from_wkb(^QueryUtils.wrap_wkb(wkb, unquote(repo)), ^point.srid)
          )
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result == point
      end
    end

    describe "SQL/MM2: point_n (#{repo})" do
      test "returns a point by index" do
        line = Fixtures.linestring()
        expected = %Geometry.Point{coordinates: Enum.at(line.path, -1), srid: line.srid}
        unquote(repo).insert(%GeoType{t: "hello", linestring: line})

        query =
          from(location in GeoType, select: MM2.point_n(location.linestring, 2))

        result =
          unquote(repo).one(query)
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result == expected
      end
    end

    describe "SQL/MM2: point_on_surface (#{repo})" do
      test "makes a point from WKB" do
        result =
          from(location in Location,
            select: MM2.point_on_surface(location.geom)
          )
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert %Geometry.Point{} = result
      end
    end

    describe "SQL/MM2: polygon_from_text (#{repo})" do
      test "makes a point from WKT" do
        polygon = Fixtures.polygon(:donut)
        wkt = Geometry.to_wkt(polygon)

        result =
          from(location in Location, select: MM2.polygon_from_text(^wkt, ^polygon.srid))
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result == polygon
      end
    end

    describe "SQL/MM2: relate (#{repo})" do
      test "calculates the spatial relationship between two geometries" do
        polygonA = Fixtures.polygon(:donut)
        polygonB = Fixtures.polygon()

        result =
          from(location in Location, select: MM2.relate(^polygonA, ^polygonB))
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result == "212FF1FF2"
      end

      test "calculates the spatial relationship between two geometries, with a mode" do
        polygonA = Fixtures.polygon(:donut)
        polygonB = Fixtures.polygon()

        result =
          from(location in Location,
            select: MM2.relate(^polygonA, ^polygonB, :multivalent_endpoint)
          )
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result == "212FF1FF2"
      end

      test "confirms the spatial relationship between two geometries" do
        polygonA = Fixtures.polygon(:donut)
        polygonB = Fixtures.polygon()

        result =
          from(location in Location,
            select: MM2.relate(^polygonA, ^polygonB, "212FF1FF2")
          )
          |> unquote(repo).one()
          |> unquote(repo).to_boolean()

        assert result
      end
    end

    describe "SQL/MM2: srid (#{repo})" do
      test "extracts the srid from a geometry" do
        result =
          from(location in Location, select: MM2.srid(location.geom))
          |> unquote(repo).one()

        assert 4326 = result
      end
    end

    describe "SQL/MM2: start_point (#{repo})" do
      test "returns the last point of a line" do
        line = Fixtures.linestring()
        expected = %Geometry.Point{coordinates: Enum.at(line.path, 0), srid: line.srid}
        unquote(repo).insert(%GeoType{t: "hello", linestring: line})

        result =
          from(location in GeoType, select: MM2.start_point(location.linestring))
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result == expected
      end
    end

    describe "SQL/MM2: sym_difference (#{repo})" do
      test "returns the differences between two geometries" do
        line = Fixtures.linestring()

        result =
          from(location in Location, select: MM2.sym_difference(location.geom, ^line))
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert match?(
                 %Geometry.GeometryCollection{
                   geometries: [%Geometry.LineString{}, %Geometry.Polygon{}]
                 },
                 result
               ) or
                 match?(
                   %Geometry.GeometryCollection{
                     geometries: [%Geometry.Polygon{}, %Geometry.LineString{}]
                   },
                   result
                 )
      end
    end

    describe "SQL/MM2: touches (#{repo})" do
      test "changes the srid of a geometry" do
        line = Fixtures.linestring()

        result =
          from(location in Location, limit: 1, select: MM2.touches(location.geom, ^line))
          |> unquote(repo).one()
          |> unquote(repo).to_boolean()

        refute result
      end
    end

    describe "SQL/MM2: transform (#{repo})" do
      test "changes the srid of a geometry" do
        query = from(location in Location, limit: 1, select: MM2.transform(location.geom, 3452))
        result = unquote(repo).one(query) |> GeoSQL.decode_geometry(unquote(repo))

        assert result.srid == 3452
      end
    end

    describe "SQL/MM2: union (#{repo})" do
      test "combines two polygons" do
        polygonA = Fixtures.polygon()
        polygonB = Fixtures.polygon(:piece)

        expected = %Geometry.MultiPolygon{
          polygons: [polygonA.rings, polygonB.rings],
          srid: polygonA.srid
        }

        result =
          from(location in Location,
            select:
              MM2.union(
                QueryUtils.cast_to_geometry(^polygonA, unquote(repo)),
                QueryUtils.cast_to_geometry(^polygonB, unquote(repo))
              )
          )
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        assert result == expected
      end

      if repo.has_array_literals?() do
        test "combines a list of polygons" do
          polygonA = Fixtures.polygon()
          polygonB = Fixtures.polygon(:piece)

          result =
            from(location in Location,
              select:
                MM2.union([
                  QueryUtils.cast_to_geometry(^polygonB, unquote(repo)),
                  QueryUtils.cast_to_geometry(^polygonA, unquote(repo))
                ])
            )
            |> unquote(repo).one()
            |> GeoSQL.decode_geometry(unquote(repo))

          assert %Geometry.MultiPolygon{} = result
        end
      end
    end

    describe "SQL/MM2: within (#{repo})" do
      test "determines if a geometry is another" do
        polygon = Fixtures.polygon()
        linestring = Fixtures.linestring()

        result =
          from(location in Location, select: MM2.within(^polygon, ^linestring))
          |> unquote(repo).one()
          |> unquote(repo).to_boolean()

        refute result
      end
    end

    describe "SQL/MM2: x (#{repo})" do
      test "extracts the x coordinate" do
        pointz = Fixtures.point(:z)
        unquote(repo).insert(%GeoType{t: "hello", pointz: pointz})

        result =
          from(location in GeoType, select: MM2.x(location.pointz))
          |> unquote(repo).one()

        assert result == Enum.at(pointz.coordinates, 0)
      end
    end

    describe "SQL/MM2: y (#{repo})" do
      test "extracts the y coordinate" do
        pointz = Fixtures.point(:z)
        unquote(repo).insert(%GeoType{t: "hello", pointz: pointz})

        result =
          from(location in GeoType, select: MM2.y(location.pointz))
          |> unquote(repo).one()

        assert result == Enum.at(pointz.coordinates, 1)
      end
    end

    describe "SQL/MM2: z (#{repo})" do
      test "extracts the z coordinate" do
        pointz = Fixtures.point(:z)
        unquote(repo).insert(%GeoType{t: "hello", pointz: pointz})

        result =
          from(location in GeoType, select: MM2.z(location.pointz))
          |> unquote(repo).one()

        assert result == Enum.at(pointz.coordinates, 2)
      end
    end

    describe "SQL/MM2: in functions(#{repo})" do
      test "works via a module function " do
        query =
          Fixtures.multipolygon()
          |> Example.example_query()

        result = unquote(repo).one(query)
        assert result == 0
      end
    end
  end
end
