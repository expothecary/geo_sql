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
