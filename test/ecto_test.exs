defmodule GeoSQL.Ecto.Test do
  use ExUnit.Case, async: true
  @moduletag :ecto

  import Ecto.Query
  use GeoSQL.Test.Helper

  alias GeoSQL.Test.Schema.{
    Location,
    Geographies,
    LocationMulti,
    GeoType,
    WrongGeoType
  }

  for repo <- Helper.repos() do
    describe "Basic geometry queries #{repo}" do
      test "geometry equality" do
        geom = Fixtures.multipolygon()

        geom_comparison =
          Fixtures.multipolygon(:comparison)

        unquote(repo).insert(%Location{name: "Smallville", geom: geom})

        results =
          from(location in Location,
            limit: 1,
            select: %{
              raw_different: location.geom == ^geom_comparison,
              raw_same: location.geom == ^geom
            }
          )
          |> unquote(repo).one()

        assert match?(%{raw_same: true, raw_different: false}, results)
      end

      test "GeoSQL.Geometry.Point" do
        point = %Geometry.Point{coordinates: [30, -90], srid: 4326}
        linestring = %Geometry.LineString{path: [[30, -90], [30, -91]], srid: 4326}

        {:ok, _} =
          Ecto.Adapters.SQL.query(
            unquote(repo).get_dynamic_repo(),
            "INSERT INTO specified_columns (id, t, point, linestring) VALUES ($1, $2, $3, $4)",
            [
              42,
              "test",
              point,
              linestring
            ]
          )

        assert match?(
                 [
                   %GeoType{
                     id: 42,
                     t: "test",
                     point: %Geometry.Point{srid: 4326},
                     linestring: %Geometry.LineString{srid: 4326}
                   }
                 ],
                 unquote(repo).all(GeoType)
               )

        assert_raise(ArgumentError, fn -> unquote(repo).all(WrongGeoType) end)
      end

      test "query multipoint" do
        geom = Fixtures.multipolygon()

        unquote(repo).insert(%Location{name: "hello", geom: geom})
        query = from(location in Location, limit: 5, select: location)
        results = unquote(repo).all(query)

        assert geom == hd(results).geom
      end

      test "geography" do
        geom = %Geometry.Point{coordinates: [30, -90], srid: 4326}

        unquote(repo).insert(%Geographies{name: "hello", geom: geom})
        query = from(location in Geographies, limit: 5, select: location)
        results = unquote(repo).all(query)

        assert geom == hd(results).geom
      end

      test "cast point" do
        geom = %Geometry.Point{coordinates: [30, -90], srid: 4326}

        unquote(repo).insert(%Geographies{name: "hello", geom: geom})
        query = from(location in Geographies, limit: 5, select: location)
        results = unquote(repo).all(query)

        result = hd(results)

        json = Geometry.to_geo_json(%Geometry.Point{coordinates: [31, -90], srid: 4326})

        changeset =
          Ecto.Changeset.cast(result, %{title: "Hello", geom: json}, [:name, :geom])
          |> Ecto.Changeset.validate_required([:name, :geom])

        assert changeset.changes == %{geom: %Geometry.Point{coordinates: [31, -90], srid: 4326}}
      end

      test "cast point from map" do
        geom = %Geometry.Point{coordinates: [30, -90], srid: 4326}

        unquote(repo).insert(%Geographies{name: "hello", geom: geom})
        query = from(location in Geographies, limit: 5, select: location)
        results = unquote(repo).all(query)

        result = hd(results)

        json = %{
          "type" => "Point",
          "crs" => %{"type" => "name", "properties" => %{"name" => "EPSG:4326"}},
          "coordinates" => [31, -90]
        }

        changeset =
          Ecto.Changeset.cast(result, %{title: "Hello", geom: json}, [:name, :geom])
          |> Ecto.Changeset.validate_required([:name, :geom])

        assert changeset.changes == %{geom: %Geometry.Point{coordinates: [31, -90], srid: 4326}}
      end
    end

    describe "Basic mutations #{repo}" do
      test "insert multiple geometry types" do
        geom1 = %Geometry.Point{coordinates: [30, -90], srid: 4326}
        geom2 = %Geometry.LineString{path: [[30, -90], [30, -91]], srid: 4326}

        unquote(repo).insert(%LocationMulti{name: "hello point", geom: geom1})
        unquote(repo).insert(%LocationMulti{name: "hello line", geom: geom2})
        query = from(location in LocationMulti, select: location)
        [m1, m2] = unquote(repo).all(query)

        assert m1.geom == geom1
        assert m2.geom == geom2
      end
    end
  end

  if Enum.member?(Helper.repos(:all), GeoSQL.Test.SpatiaLite.Repo) do
    alias GeoSQL.Test.Schema.Geopackage

    describe "GeoPackage geometry in schemas" do
      test "decodes a Geopackage-encoded polygon" do
        query = from(g in Geopackage, where: g.id == 3)
        result = GeopackageRepo.one(query)

        assert match?(
                 %Geopackage{
                   id: 3,
                   name: "Sanctuary- ABSOLUTELY NO TRESPASSING!",
                   shape: %Geometry.MultiPolygon{}
                 },
                 result
               )
      end
    end
  end
end
