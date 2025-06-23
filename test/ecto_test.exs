defmodule GeoSQL.Ecto.Test do
  use ExUnit.Case, async: true
  import Ecto.Query
  use GeoSQL.Test.Helper

  alias GeoSQL.Test.Schema.{Location, Geographies, LocationMulti, GeoTypes, WrongGeoTypes}

  describe "Basic geometry queries" do
    test "GeoSQL.Geometry.Point" do
      point = %Geo.Point{coordinates: {30, -90}, srid: 4326}
      linestring = %Geo.LineString{coordinates: [{30, -90}, {30, -91}], srid: 4326}

      {:ok, _} =
        Ecto.Adapters.SQL.query(
          PostGISRepo.get_dynamic_repo(),
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
                 %GeoTypes{
                   id: 42,
                   t: "test",
                   point: %Geo.Point{srid: 4326},
                   linestring: %Geo.LineString{srid: 4326}
                 }
               ],
               PostGISRepo.all(GeoTypes)
             )

      assert_raise(ArgumentError, fn -> PostGISRepo.all(WrongGeoTypes) end)
    end

    test "query multipoint" do
      geom = Geo.WKB.decode!(Fixtures.multipoint_wkb())

      PostGISRepo.insert(%Location{name: "hello", geom: geom})
      query = from(location in Location, limit: 5, select: location)
      results = PostGISRepo.all(query)

      assert geom == hd(results).geom
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
  end

  describe "Basic mutations" do
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
  end
end
