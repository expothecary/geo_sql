defmodule GeoSQL.MM3Functions.Test do
  use ExUnit.Case, async: true
  @moduletag :mm3

  import Ecto.Query
  use GeoSQL.MM3
  use GeoSQL.Common
  use GeoSQL.QueryUtils
  use GeoSQL.Test.Helper

  alias GeoSQL.Test.Schema.{LocationMulti, GeoType, Geographies}
  alias GeoSQL.Test.Fixtures

  supports_mm3 = [GeoSQL.Test.PostGIS.Repo]

  for repo <- Helper.repos(), Enum.member?(supports_mm3, repo) do
    describe "MM3: coord_dim (#{repo})" do
      test "extracts dimensionality from geometry" do
        point = Fixtures.point()
        pointz = Fixtures.point(:z)

        unquote(repo).insert(%GeoType{point: point, pointz: pointz})

        result =
          from(g in GeoType,
            select: [
              MM3.coord_dim(g.point),
              MM3.coord_dim(g.pointz)
            ]
          )
          |> unquote(repo).one()

        #         assert result == ["XY", "XYZ"]
        assert result == [2, 3]
      end
    end

    describe "MM3: distance (#{repo})" do
      test "order by distance" do
        geom1 = %Geometry.Point{coordinates: [30, -90], srid: 4326}
        geom2 = %Geometry.Point{coordinates: [30, -91], srid: 4326}
        geom3 = %Geometry.Point{coordinates: [60, -91], srid: 4326}

        unquote(repo).insert(%Geographies{name: "there", geom: geom2})
        unquote(repo).insert(%Geographies{name: "here", geom: geom1})
        unquote(repo).insert(%Geographies{name: "way over there", geom: geom3})

        query =
          from(
            location in Geographies,
            limit: 5,
            select: location,
            order_by:
              MM3.ThreeD.distance(
                QueryUtils.cast_to_geometry(location.geom, unquote(repo)),
                QueryUtils.cast_to_geometry(^geom1, unquote(repo))
              )
          )

        result =
          query
          |> unquote(repo).all()
          |> Enum.map(fn x -> x.name end)

        assert ["here", "there", "way over there"] == result,
               "#{unquote(repo)} failed"
      end
    end

    describe "MM3: geom_from_text (#{repo})" do
      test "returns our point" do
        # wkt does not include the SRID, so set the SRID to 0
        point = Fixtures.point() |> Map.put(:srid, 0)
        wkt = Geometry.to_wkt(point)

        unquote(repo).insert(%GeoType{point: point})

        result =
          from(g in GeoType,
            select: MM3.geom_from_text(^wkt)
          )
          |> unquote(repo).one()

        assert unquote(repo).to_boolean(result)
      end
    end

    describe "MM3: locate_along (#{repo})" do
      test "returns matching points from a PolygonM" do
        linestringzm = Fixtures.linestring(:zm)

        unquote(repo).insert(%GeoType{linestringzm: linestringzm})

        result =
          from(g in GeoType,
            select: MM3.locate_along(g.linestringzm, 10)
          )
          |> unquote(repo).one()
          |> QueryUtils.decode_geometry(unquote(repo))

        assert %Geometry.MultiPointZM{} = result
        assert Enum.count(result.points) == 3
      end

      test "returns matching points from a PolygonM past an offset" do
        linestringzm = Fixtures.linestring(:zm)

        unquote(repo).insert(%GeoType{linestringzm: linestringzm})

        result =
          from(g in GeoType,
            select: MM3.locate_along(g.linestringzm, 10, 2)
          )
          |> unquote(repo).one()
          |> QueryUtils.decode_geometry(unquote(repo))

        assert %Geometry.MultiPointZM{} = result
        assert Enum.count(result.points) == 5
      end
    end

    describe "MM3: locate_between (#{repo})" do
      test "returns matching points from a PolygonM" do
        linestringzm = Fixtures.linestring(:zm)

        unquote(repo).insert(%GeoType{linestringzm: linestringzm})

        result =
          from(g in GeoType,
            select: MM3.locate_between(g.linestringzm, 10, 20)
          )
          |> unquote(repo).one()
          |> QueryUtils.decode_geometry(unquote(repo))

        assert %Geometry.MultiLineStringZM{} = result
        assert Enum.count(result.line_strings) == 2
      end

      test "returns matching points from a PolygonM past an offset" do
        linestringzm = Fixtures.linestring(:zm)

        unquote(repo).insert(%GeoType{linestringzm: linestringzm})

        result =
          from(g in GeoType,
            select: MM3.locate_between(g.linestringzm, 10, 20, 0.5)
          )
          |> unquote(repo).one()
          |> QueryUtils.decode_geometry(unquote(repo))

        assert %Geometry.MultiLineString{} = result
        assert Enum.count(result.line_strings) == 2
      end
    end

    describe "ordering_equals (#{repo})" do
      test "returns true with identical geometry" do
        linestring = Fixtures.linestring()
        unquote(repo).insert(%GeoType{linestring: linestring})

        query =
          from(g in GeoType,
            select: MM3.ordering_equals(g.linestring, ^linestring)
          )

        result = unquote(repo).one(query)

        assert unquote(repo).to_boolean(result)
      end

      test "returns false with differing geometry" do
        linestring = Fixtures.linestring()
        linestring2 = Fixtures.linestring(:intersects)
        unquote(repo).insert(%GeoType{linestring: linestring})

        query =
          from(g in GeoType,
            select: MM3.ordering_equals(g.linestring, ^linestring2)
          )

        result = unquote(repo).one(query)

        refute unquote(repo).to_boolean(result)
      end
    end

    describe "is_empty/1 (#{repo})" do
      test "returns true for an empty geometry" do
        empty_point = %Geometry.Point{coordinates: [], srid: 4326}

        unquote(repo).insert(%LocationMulti{name: "empty_point", geom: empty_point})

        query =
          from(l in LocationMulti,
            where: l.name == "empty_point",
            select: MM3.is_empty(l.geom)
          )

        result = unquote(repo).one(query)

        # SQLITE "does not know" on empty points, so returns a valid -1
        assert result == -1 or unquote(repo).to_boolean(result), "#{unquote(repo)} failed"
      end
    end

    test "returns false for a non-empty geometry (#{repo})" do
      point = %Geometry.Point{coordinates: [0, 0], srid: 4326}
      unquote(repo).insert(%LocationMulti{name: "non_empty", geom: point})

      query =
        from(l in LocationMulti,
          where: l.name == "non_empty",
          select: MM3.is_empty(l.geom)
        )

      result = unquote(repo).one(query)
      assert not unquote(repo).to_boolean(result), "#{unquote(repo)} failed"
    end
  end
end
