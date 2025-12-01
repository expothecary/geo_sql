defmodule GeoSQL.CommonFunctions.Test do
  use ExUnit.Case, async: true
  @moduletag :common

  import Ecto.Query
  use GeoSQL.MM
  use GeoSQL.PostGIS
  use GeoSQL.Common
  use GeoSQL.QueryUtils
  use GeoSQL.Test.Helper
  alias GeoSQL.Test.Helper

  alias GeoSQL.Test.Schema.{Location, LocationMulti, GeoType}

  for repo <- Helper.repos() do
    describe "Common: add_measure (#{repo})" do
      test "adds measure values to a line" do
        line = Fixtures.linestring()

        unquote(repo).insert(%GeoType{t: "hello", linestring: line})

        query =
          from(location in GeoType, select: Common.add_measure(location.linestring, 1, 100))

        assert [%Geometry.LineStringM{path: path}] =
                 unquote(repo).all(query)
                 |> QueryUtils.decode_geometry(unquote(repo))

        assert match?([[_, _, 1.0], [_, _, 100.0]], path)
      end
    end

    describe "Common: add_point (#{repo})" do
      test "adds a point to a line" do
        line = Fixtures.linestring()
        point = Fixtures.point()

        unquote(repo).insert(%GeoType{t: "hello", linestring: line, point: point})

        query =
          from(location in GeoType, select: Common.add_point(location.linestring, location.point))

        assert [%Geometry.LineString{path: path}] =
                 unquote(repo).all(query)
                 |> QueryUtils.decode_geometry(unquote(repo))

        assert length(path) == Enum.count(line.path) + 1
      end

      test "-1 adds a point to the end of a line" do
        line = Fixtures.linestring()
        point = Fixtures.point()

        unquote(repo).insert(%GeoType{t: "hello", linestring: line, point: point})

        query =
          from(location in GeoType, select: Common.add_point(location.linestring, location.point))

        assert [%Geometry.LineString{path: path}] =
                 unquote(repo).all(query)
                 |> QueryUtils.decode_geometry(unquote(repo))

        assert length(path) == Enum.count(line.path) + 1
        assert Enum.at(path, 2) == point.coordinates
      end

      test "0 prepends a point to the line" do
        line = Fixtures.linestring()
        point = Fixtures.point()

        unquote(repo).insert(%GeoType{t: "hello", linestring: line, point: point})

        query =
          from(location in GeoType, select: Common.add_point(location.linestring, location.point))

        assert [%Geometry.LineString{path: path}] =
                 unquote(repo).all(query)
                 |> QueryUtils.decode_geometry(unquote(repo))

        assert length(path) == Enum.count(line.path) + 1
        assert Enum.at(path, 0) == point.coordinates
      end
    end

    describe "Common: as_ewkb (#{repo})" do
      test "returns correct binary data" do
        ewkb = Fixtures.multipolygon_ewkb()
        geom = Fixtures.multipolygon()

        unquote(repo).insert(%Location{name: "hello", geom: geom})

        query = from(location in Location, select: Common.as_ewkb(location.geom, unquote(repo)))

        assert [^ewkb] = unquote(repo).all(query)
      end
    end

    describe "Common: as_ewkt (#{repo})" do
      test "returns correct binary data" do
        geom = Fixtures.multipolygon()

        unquote(repo).insert(%Location{name: "hello", geom: geom})

        query = from(location in Location, select: Common.as_ewkt(location.geom, unquote(repo)))
        [ewkt] = unquote(repo).all(query)
        hydrated = Geometry.from_ewkt!(ewkt)
        assert geom.srid == hydrated.srid
        assert Helper.fuzzy_match_geometry(geom.polygons, hydrated.polygons)
      end
    end

    describe "Common: as_geojson (#{repo})" do
      test "returns correct binary data" do
        geom = Fixtures.multipolygon()
        unquote(repo).insert(%Location{name: "hello", geom: geom})

        query =
          from(location in Location, select: Common.as_geojson(location.geom, unquote(repo)))

        [geojson] = unquote(repo).all(query)

        hydrated =
          geojson
          |> Jason.decode!()
          |> Geometry.from_geo_json!()

        assert 4326 = hydrated.srid
        assert Helper.fuzzy_match_geometry(geom.polygons, hydrated.polygons)
      end
    end

    describe "Common: as_gml (#{repo})" do
      test "returns correct v3 gml" do
        geom = Fixtures.multipolygon()
        unquote(repo).insert(%Location{name: "hello", geom: geom})

        query =
          from(location in Location, select: Common.as_gml(location.geom, 3, 4, unquote(repo)))

        [gml] = unquote(repo).all(query)

        assert String.starts_with?(gml, "<gml:MultiSurface")
        assert Regex.run(~r/srsName=".*EPSG:4326"/, gml) != nil
        assert String.contains?(gml, ~s|srsDimension="2"|)
      end

      test "returns correct v2 gml" do
        geom = Fixtures.multipolygon()
        unquote(repo).insert(%Location{name: "hello", geom: geom})

        query =
          from(location in Location, select: Common.as_gml(location.geom, 2, 4, unquote(repo)))

        [gml] = unquote(repo).all(query)

        assert String.starts_with?(gml, "<gml:MultiPolygon")
        assert Regex.run(~r/srsName=".*EPSG:4326"/, gml) != nil
        assert not String.contains?(gml, ~s|srsDimension="2"|)
      end
    end

    describe "Common: as_kml (#{repo})" do
      test "returns correct kml with precision 1" do
        geom = Fixtures.multipolygon()
        unquote(repo).insert(%Location{name: "hello", geom: geom})

        query =
          from(location in Location,
            select: Common.as_kml(location.geom, 1, "TestKML", unquote(repo))
          )

        [kml] = unquote(repo).all(query)

        assert String.contains?(kml, "MultiGeometry>")
        assert String.contains?(kml, "TestKML")
        assert String.contains?(kml, ~s|coordinates>-8.9,37|)
      end

      test "returns correct kml with higher precision" do
        geom = Fixtures.multipolygon()
        unquote(repo).insert(%Location{name: "hello", geom: geom})

        query =
          from(location in Location,
            select: Common.as_kml(location.geom, 5, "TestKML", unquote(repo))
          )

        [kml] =
          unquote(repo).all(query)

        assert String.contains?(kml, "MultiGeometry>")
        assert String.contains?(kml, "TestKML")
        assert String.contains?(kml, ~s|coordinates>-8.91606,37.01479|)
      end
    end

    describe "Common: azimuth (#{repo})" do
      test "returns a useful value" do
        db_point = Fixtures.point()
        client_point = Fixtures.point(:comparison)

        unquote(repo).insert(%GeoType{t: "azimuth", point: db_point})

        query =
          from(g in GeoType, select: Common.azimuth(g.point, ^client_point))

        assert [value] = unquote(repo).all(query)
        assert is_number(value)
      end
    end

    describe "Common: bd_m_poly_from_text (#{repo})" do
      test "produces a MultiPolygon" do
        multilinestering = Fixtures.multilinestring(:polygonizable)

        unquote(repo).insert(%GeoType{
          t: "bd_m_poly_from_text",
          multilinestring: multilinestering
        })

        query =
          from(g in GeoType,
            select:
              Common.bd_m_poly_from_text(
                MM.as_text(g.multilinestring),
                ^multilinestering.srid
              )
          )

        [value] =
          unquote(repo).all(query)
          |> QueryUtils.decode_geometry(unquote(repo))

        assert %Geometry.MultiPolygon{} = value
      end
    end

    describe "Common: bd_poly_from_text (#{repo})" do
      test "produces a Polygon" do
        multilinestering = Fixtures.multilinestring(:polygonizable)

        unquote(repo).insert(%GeoType{
          t: "bd_poly_from_text",
          multilinestring: multilinestering
        })

        query =
          from(g in GeoType,
            select:
              Common.bd_poly_from_text(
                MM.as_text(g.multilinestring),
                ^multilinestering.srid
              )
          )

        [value] =
          unquote(repo).all(query)
          |> QueryUtils.decode_geometry(unquote(repo))

        assert %Geometry.Polygon{} = value
      end
    end

    describe "Common: build_area (#{repo})" do
      test "returns a polygon with a hole" do
        collection = Fixtures.geometry_collection(:courtyard)

        expected = %Geometry.Polygon{
          rings: [
            [[180, 40], [30, 20], [20, 90], [80, 120], [80, 90], [160, 160], [180, 40]],
            [[150, 80], [120, 130], [80, 60], [150, 80]]
          ],
          srid: 4326
        }

        unquote(repo).insert(%Location{
          name: "build_area",
          geom: collection
        })

        query =
          from(l in Location,
            select: Common.build_area(l.geom)
          )

        [value] =
          unquote(repo).all(query)
          |> QueryUtils.decode_geometry(unquote(repo))

        assert Helper.fuzzy_match_geometry(expected, value)
      end
    end

    describe "Common: closest_point (#{repo})" do
      test "returns a point" do
        line = Fixtures.linestring()
        polygon = Fixtures.polygon()

        unquote(repo).insert(%GeoType{t: "hello", linestring: line, polygon: polygon})

        query =
          from(location in GeoType,
            select:
              Common.closest_point(location.linestring, location.polygon, false, unquote(repo))
          )

        result =
          unquote(repo).one(query)
          |> QueryUtils.decode_geometry(unquote(repo))

        assert %Geometry.Point{} = result
      end

      test "uses the spheroid when directed" do
        line = Fixtures.linestring()
        polygon = Fixtures.polygon()

        unquote(repo).insert(%GeoType{t: "hello", linestring: line, polygon: polygon})

        query =
          from(location in GeoType,
            select:
              Common.closest_point(location.linestring, location.polygon, true, unquote(repo))
          )

        result =
          unquote(repo).one(query)
          |> QueryUtils.decode_geometry(unquote(repo))

        assert %Geometry.Point{} = result
      end
    end

    describe "Common: collection_extract (#{repo})" do
      test "extracts points, lines, polygons" do
        collection = Fixtures.geometry_collection()
        line = Fixtures.linestring()

        unquote(repo).insert(%GeoType{t: "hello", linestring: line})

        query =
          from(location in GeoType,
            select: %{
              point: Common.collection_extract(^collection, :point),
              linestring: Common.collection_extract(^collection, :linestring),
              polygon: Common.collection_extract(^collection, :polygon)
            }
          )

        result =
          unquote(repo).one(query)
          |> QueryUtils.decode_geometry(unquote(repo), [:point, :linestring, :polygon])

        case unquote(repo) do
          GeoSQL.Test.SpatiaLite.Repo ->
            assert match?(
                     %{
                       point: %Geometry.Point{},
                       linestring: %Geometry.LineString{},
                       polygon: nil
                     },
                     result
                   )

          _ ->
            assert match?(
                     %{
                       point: %Geometry.MultiPoint{},
                       linestring: %Geometry.MultiLineString{},
                       polygon: %Geometry.MultiPolygon{}
                     },
                     result
                   )
        end
      end
    end

    describe "Common: concave_hull (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: covers (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: covered_by (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: collect (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: degrees (#{repo})" do
      test "Converts radians to degrees" do
        geom = Fixtures.point()
        unquote(repo).insert(%Location{name: "hello", geom: geom})
        query = from(location in Location, select: Common.degrees(0.5))
        result = unquote(repo).one(query)
        assert is_number(result)
      end
    end

    describe "Common: estimated_extent (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: expand (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: extent (#{repo})" do
      test "extent" do
        geom = Fixtures.multipolygon()

        unquote(repo).insert(%Location{name: "hello", geom: geom})

        query = from(location in Location, select: Common.extent(location.geom, unquote(repo)))

        assert [%Geometry.Polygon{rings: [ring]}] =
                 unquote(repo).all(query)
                 |> QueryUtils.decode_geometry(unquote(repo))

        assert length(ring) == 5
      end
    end

    describe "Common: flip_coordinates (#{repo})" do
      test "inverts x/y coordinates" do
        point = Fixtures.point()
        flipped = %Geometry.Point{coordinates: Enum.reverse(point.coordinates), srid: point.srid}

        unquote(repo).insert(%GeoType{t: "flip_coordinates", point: point})

        result =
          from(g in GeoType, select: Common.flip_coordinates(g.point, unquote(repo)))
          |> unquote(repo).one()
          |> QueryUtils.decode_geometry(unquote(repo))

        assert result == flipped
      end
    end

    describe "Common: geom_from_ewkt (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: geom_from_geojson (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: geom_from_kml (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: interpolate_point (#{repo})" do
      test "modifies a LineStringM" do
        point = Fixtures.point()
        line = Fixtures.linestring(:m)

        unquote(repo).insert(%GeoType{t: "interpolate_point", linestringm: line})

        result =
          from(g in GeoType, select: Common.interpolate_point(g.linestringm, ^point))
          |> unquote(repo).one()

        assert is_number(result)
      end
    end

    describe "Common: is_polygon_clockwise (#{repo})" do
      test "detects clockwise-ness" do
        polygon = Fixtures.polygon()

        unquote(repo).insert(%GeoType{t: "interpolate_point", polygon: polygon})

        result =
          from(g in GeoType, select: Common.is_polygon_clockwise(g.polygon))
          |> unquote(repo).one()

        assert unquote(repo).to_boolean(result)
      end
    end

    describe "Common: is_polygon_counter_clockwise (#{repo})" do
      test "detects counter-clockwise-ness" do
        polygon = Fixtures.polygon()

        unquote(repo).insert(%GeoType{t: "interpolate_point", polygon: polygon})

        result =
          from(g in GeoType, select: Common.is_polygon_counter_clockwise(g.polygon))
          |> unquote(repo).one()

        refute unquote(repo).to_boolean(result)
      end
    end

    describe "Common: is_valid_detail (#{repo})" do
      test "returns details on validity" do
        invalid_polygon = Fixtures.polygon(:invalid)
        unquote(repo).insert(%GeoType{t: "hello", polygon: invalid_polygon})

        query = from(g in GeoType, select: Common.is_valid_detail(g.polygon))

        result = unquote(repo).one(query) |> QueryUtils.decode_geometry(unquote(repo))

        assert match?(%Geometry.Point{}, result) or
                 match?({false, "Self-intersection", %Geometry.Point{}}, result)
      end
    end

    describe "Common: is_valid_reason (#{repo})" do
      test "returns reason for validity" do
        invalid_polygon = Fixtures.polygon(:invalid)
        unquote(repo).insert(%GeoType{t: "hello", polygon: invalid_polygon})

        query = from(g in GeoType, select: Common.is_valid_reason(g.polygon))

        result = unquote(repo).one(query)

        assert is_binary(result)
      end
    end

    describe "Common: largest_empty_circle (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: line_interpolate_point (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: line_interpolate_points (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: line_locate_point (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: line_substring (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: line_merge/2 (#{repo})" do
      supports_directed_merges = [GeoSQL.Test.PostGIS.Repo]

      if Enum.member?(supports_directed_merges, repo) do
        test "lines with opposite directions not merged if directed is true" do
          multiline = %Geometry.MultiLineString{
            line_strings: [
              [[60, 30], [10, 70]],
              [[120, 50], [60, 30]],
              [[120, 50], [180, 30]]
            ],
            srid: 4326
          }

          unquote(repo).insert(%LocationMulti{name: "lines with direction", geom: multiline})

          query =
            from(
              location in LocationMulti,
              where: location.name == "lines with direction",
              select: Common.line_merge(location.geom, true, unquote(repo))
            )

          result = unquote(repo).one(query) |> QueryUtils.decode_geometry(unquote(repo))

          # Verify the result is still a MultiLineString with only 2 lines merged

          assert %Geometry.MultiLineString{} = result

          assert length(result.line_strings) == 2

          expected_linestrings = [
            [[120, 50], [60, 30], [10, 70]],
            [[120, 50], [180, 30]]
          ]

          sorted_result = Enum.sort_by(result.line_strings, fn linestring -> hd(linestring) end)

          sorted_expected =
            Enum.sort_by(expected_linestrings, fn linestring -> hd(linestring) end)

          assert sorted_result == sorted_expected
        end
      end

      test "lines with opposite directions merged if directed is false" do
        multiline = %Geometry.MultiLineString{
          line_strings: [
            [[60, 30], [10, 70]],
            [[120, 50], [60, 30]],
            [[120, 50], [180, 30]]
          ],
          srid: 4326
        }

        unquote(repo).insert(%LocationMulti{name: "lines with direction", geom: multiline})

        query =
          from(
            location in LocationMulti,
            where: location.name == "lines with direction",
            select: Common.line_merge(location.geom, false)
          )

        result =
          unquote(repo).one(query)
          |> QueryUtils.decode_geometry(unquote(repo))

        assert %Geometry.LineString{} = result

        assert result.path == [
                 [180, 30],
                 [120, 50],
                 [60, 30],
                 [10, 70]
               ]
      end
    end

    describe "Common: locate_along (#{repo})" do
      test "untested" do
        line = Fixtures.linestring(:m)
        [_, point | _] = line.path

        expected = [
          [%Geometry.PointM{coordinates: point, srid: line.srid}],
          [%Geometry.MultiPointM{points: [point], srid: line.srid}]
        ]

        unquote(repo).insert(%GeoType{t: "locate_along", linestringm: line})

        result =
          from(g in GeoType, select: Common.locate_along(g.linestringm, 10))
          |> unquote(repo).all()
          |> QueryUtils.decode_geometry(unquote(repo))

        assert Enum.any?(expected, fn expected -> expected == result end)
      end
    end

    describe "Common: locate_between (#{repo})" do
      test "untested" do
        line = Fixtures.linestring(:m)
        coordinates = Enum.slice(line.path, 1, 2)

        expected = [
          [%Geometry.LineStringM{path: coordinates, srid: line.srid}],
          [%Geometry.MultiLineStringM{line_strings: [coordinates], srid: 4326}]
        ]

        unquote(repo).insert(%GeoType{t: "locate_between", linestringm: line})

        result =
          from(g in GeoType, select: Common.locate_between(g.linestringm, 10, 30))
          |> unquote(repo).all()
          |> QueryUtils.decode_geometry(unquote(repo))

        assert Enum.any?(expected, fn expected -> expected == result end)
      end
    end

    describe "Common: make_point (#{repo})" do
      test "makes a 2D point" do
        line = Fixtures.linestring()
        point = Fixtures.point()

        unquote(repo).insert(%GeoType{t: "make_point", linestring: line, point: point})

        query = from(g in GeoType, select: Common.make_point(1, 2, unquote(repo)))

        assert [%Geometry.Point{coordinates: [1.0, 2.0], srid: 0}] =
                 unquote(repo).all(query)
                 |> QueryUtils.decode_geometry(unquote(repo))
      end

      test "makes a 3D point" do
        line = Fixtures.linestring()
        point = Fixtures.point()

        unquote(repo).insert(%GeoType{t: "hello", linestring: line, point: point})

        query = from(location in GeoType, select: Common.make_point_z(1, 2, 3, unquote(repo)))

        assert [%Geometry.PointZ{coordinates: [1.0, 2.0, 3.0]}] =
                 unquote(repo).all(query)
                 |> QueryUtils.decode_geometry(unquote(repo))
      end

      test "makes a 2D point with a measure" do
        line = Fixtures.linestring()
        point = Fixtures.point()

        unquote(repo).insert(%GeoType{t: "hello", linestring: line, point: point})

        query = from(location in GeoType, select: Common.make_point_m(1, 2, 3, unquote(repo)))

        assert [%Geometry.PointM{coordinates: [1.0, 2.0, 3.0]}] =
                 unquote(repo).all(query)
                 |> QueryUtils.decode_geometry(unquote(repo))
      end

      test "makes a 3D point with a measure" do
        line = Fixtures.linestring()
        point = Fixtures.point()

        unquote(repo).insert(%GeoType{t: "hello", linestring: line, point: point})

        query = from(location in GeoType, select: Common.make_point_zm(1, 2, 3, 4, unquote(repo)))

        assert [%Geometry.PointZM{coordinates: [1.0, 2.0, 3.0, 4.0]}] =
                 unquote(repo).all(query)
                 |> QueryUtils.decode_geometry(unquote(repo))
      end
    end

    describe "Common: make_valid (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: max_coord (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: max_distance (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: maximum_inscribed_circle (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: min_coord (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: minimum_bounding_circle (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: minimum_bounding_radius (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: minimum_clearance (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common:  multi(#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: node (#{repo})" do
      supports_self_intersection = [GeoSQL.Test.PostGIS.Repo]

      test "nodes from a linestring" do
        coordinates = [[0, 0, 0], [1, 1, 1], [2, 2, 2]]

        # Create a self-intersecting linestring (crossing at point [1, 1, 1])
        linestring = %Geometry.LineStringZ{
          path: coordinates,
          srid: 4326
        }

        unquote(repo).insert(%LocationMulti{name: "intersecting lines", geom: linestring})

        query =
          from(
            location in LocationMulti,
            select: Common.node(location.geom)
          )

        result =
          unquote(repo).one(query)
          |> QueryUtils.decode_geometry(unquote(repo))

        assert %Geometry.LineStringZ{} = result

        assert result.path == coordinates
      end

      if Enum.member?(supports_self_intersection, repo) do
        test "self-intersecting linestring" do
          coordinates = [[0, 0, 0], [2, 2, 2], [0, 2, 0], [2, 0, 2]]
          cross_point = [1, 1, 1]

          # Create a self-intersecting linestring (crossing at point [1, 1, 1])
          linestring = %Geometry.LineStringZ{
            path: coordinates,
            srid: 4326
          }

          unquote(repo).insert(%LocationMulti{name: "intersecting lines", geom: linestring})

          query =
            from(
              location in LocationMulti,
              select: Common.node(location.geom)
            )

          result = unquote(repo).one(query) |> QueryUtils.decode_geometry(unquote(repo))

          assert %Geometry.MultiLineStringZ{} = result

          assert result.line_strings == [
                   [Enum.at(coordinates, 0), cross_point],
                   [cross_point, Enum.at(coordinates, 1), Enum.at(coordinates, 2), cross_point],
                   [cross_point, Enum.at(coordinates, 3)]
                 ]
        end

        test "intersecting multilinestring" do
          coordinates1 = [[0, 0, 0], [2, 2, 2]]
          coordinates2 = [[0, 2, 0], [2, 0, 2]]
          cross_point = [1, 1, 1]

          # Create a multilinestring that intersects (crossing at point [1, 1, 1])
          linestring = %Geometry.MultiLineStringZ{
            line_strings: [
              coordinates1,
              coordinates2
            ],
            srid: 4326
          }

          unquote(repo).insert(%LocationMulti{name: "intersecting lines", geom: linestring})

          query =
            from(
              location in LocationMulti,
              select: Common.node(location.geom)
            )

          result = unquote(repo).one(query)

          assert %Geometry.MultiLineStringZ{} = result

          assert result.line_strings == [
                   [Enum.at(coordinates1, 0), cross_point],
                   [Enum.at(coordinates2, 0), cross_point],
                   [cross_point, Enum.at(coordinates1, 1)],
                   [cross_point, Enum.at(coordinates2, 1)]
                 ]
        end
      end
    end

    describe "Common: number_of_dimension (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: number_of_points (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: number_of_rings (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: number_of_geometries (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: oriented_envelope (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: offset_curve (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: polygonize (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: project (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: radians (#{repo})" do
      test "Converts degrees to radians" do
        geom = Fixtures.point()
        unquote(repo).insert(%Location{name: "hello", geom: geom})
        query = from(location in Location, select: Common.radians(45))
        result = unquote(repo).one(query)
        assert is_number(result)
      end
    end

    describe "Common: reduce_precision (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: remove_point (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: remove_repeated_points (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: relate_match (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: reverse (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: rotate (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: segmentize (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: set_point (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: set_srid (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: shared_paths (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: shift_longitude (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: shortest_line (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: simplify (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: simplify_preserve_topology (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: snap_to_grid (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: split (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: subdivide (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: translate (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: transform_pipeline (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: triangulate_polygon (#{repo})" do
      test "untested" do
        # FIXME
      end
    end

    describe "Common: unary_union (#{repo})" do
      test "untested" do
        # FIXME
      end
    end
  end
end
