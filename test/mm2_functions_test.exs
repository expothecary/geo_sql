defmodule GeoSQL.MM2Functions.Test do
  use ExUnit.Case, async: true
  import Ecto.Query
  use GeoSQL.MM2
  use GeoSQL.Test.Helper

  alias GeoSQL.Test.Schema.Location

  setup do
    geom = Fixtures.multipoint()

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
      test "eturns a binary representation of the geometry" do
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
      full_decoding = [GeoSQL.Test.SQLite.Repo]
      full_encoding = [GeoSQL.Test.PostGIS.Repo]

      test "returns as text version" do
        result =
          from(location in Location,
            limit: 1,
            select: MM2.as_text(location.geom)
          )
          |> unquote(repo).one()
          |> GeoSQL.decode_geometry(unquote(repo))

        expected =
          if Enum.member?(unquote(full_encoding), unquote(repo)) do
            Fixtures.multipoint()
          else
            Fixtures.multipoint() |> Map.put(:srid, 0)
          end

        assert Helper.fuzzy_match_geometry(
                 expected.polygons,
                 Map.get(Geometry.from_ewkt!(result), :polygons)
               )
      end

      if Enum.member?(full_decoding, repo) do
        test "equality checks with as text" do
          geom = Fixtures.multipoint()
          comparison = Fixtures.multipoint(:comparison)

          result =
            from(location in Location,
              limit: 1,
              select: %{
                different: MM2.as_text(location.geom) == MM2.as_text(^comparison),
                same: MM2.as_text(location.geom) == MM2.as_text(^geom)
              }
            )
            |> unquote(repo).one()

          assert match?(
                   %{same: true, raw_same: true, different: false, raw_different: false},
                   result
                 )
        end
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
        comparison = Fixtures.multipoint(:comparison)

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
        comparison = Fixtures.multipoint(:comparison)

        query =
          from(location in Location, select: MM2.disjoint(location.geom, ^comparison))

        result = unquote(repo).one(query)
        refute unquote(repo).to_boolean(result)
      end
    end

    describe "SQL/MM2: distance (#{repo})" do
      test "determines the distaince between two geometries" do
        geom = Fixtures.multipoint()
        query = from(location in Location, select: MM2.distance(location.geom, ^geom))
        result = unquote(repo).one(query)
        assert result == 0
      end
    end

    describe "SQL/MM2: equals (#{repo})" do
      test "determines equality between two geometries" do
        geom = Fixtures.multipoint()
        query = from(location in Location, select: MM2.distance(location.geom, ^geom))
        result = unquote(repo).one(query)
        assert result == 0
      end
    end

    describe "SQL/MM2: transform (#{repo})" do
      test "changes the srid of a geometry" do
        query = from(location in Location, limit: 1, select: MM2.transform(location.geom, 3452))
        result = unquote(repo).one(query) |> GeoSQL.decode_geometry(unquote(repo))

        assert result.srid == 3452
      end
    end

    describe "SQL/MM2: in functions(#{repo})" do
      test "works via a module function " do
        query =
          Fixtures.multipoint()
          |> Example.example_query()

        result = unquote(repo).one(query)
        assert result == 0
      end
    end
  end
end
