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
    describe "add_measure (#{repo})" do
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

    describe "add_point (#{repo})" do
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

    describe "as_ewkb (#{repo})" do
      test "returns correct binary data" do
        ewkb = Fixtures.multipolygon_ewkb()
        geom = Fixtures.multipolygon()

        unquote(repo).insert(%Location{name: "hello", geom: geom})

        query = from(location in Location, select: Common.as_ewkb(location.geom, unquote(repo)))

        assert [^ewkb] = unquote(repo).all(query)
      end
    end

    describe "as_ewkt (#{repo})" do
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

    describe "as_geojson (#{repo})" do
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

    describe "as_gml (#{repo})" do
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

    describe "as_kml (#{repo})" do
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

    describe "azimuth (#{repo})" do
      test "returns a useful value" do
        db_point = Fixtures.point()
        client_point = Fixtures.point(:comparison)

        unquote(repo).insert(%GeoType{t: "hello", point: db_point})

        query =
          from(location in GeoType, select: Common.azimuth(location.point, ^client_point))

        assert [value] = unquote(repo).all(query)
        assert is_number(value)
      end
    end

    describe "extent (#{repo})" do
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

    describe "flip_coordinates (#{repo})" do
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

    describe "line_merge/2 (#{repo})" do
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

    describe "makepoint (#{repo})" do
      test "makes a 2D point" do
        line = Fixtures.linestring()
        point = Fixtures.point()

        unquote(repo).insert(%GeoType{t: "hello", linestring: line, point: point})

        query = from(location in GeoType, select: Common.make_point(1, 2, unquote(repo)))

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

    describe "node (#{repo})" do
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
  end
end
