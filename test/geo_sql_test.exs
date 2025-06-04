defmodule GeoSQL.Test do
  use ExUnit.Case, async: true
  use GeoSQL.Test.PostGIS.Helper

  test "insert point" do
    geo = %Geo.Point{coordinates: {30, -90}, srid: 4326}

    {:ok, _} =
      Ecto.Adapters.SQL.query(
        PostGISRepo,
        "INSERT INTO specified_columns (id, point) VALUES ($1, $2)",
        [
          42,
          geo
        ]
      )

    {:ok, result} =
      Ecto.Adapters.SQL.query(PostGISRepo, "SELECT id, point FROM specified_columns", [])

    assert(result.rows == [[42, geo]])
  end

  test "insert with text column" do
    geo = %Geo.Point{coordinates: {30, -90}, srid: 4326}

    {:ok, _} =
      Ecto.Adapters.SQL.query(
        PostGISRepo,
        "INSERT INTO specified_columns (id, t, point) VALUES ($1, $2, $3)",
        [
          42,
          "test",
          geo
        ]
      )

    {:ok, result} =
      Ecto.Adapters.SQL.query(PostGISRepo, "SELECT id, t, point FROM specified_columns", [])

    assert(result.rows == [[42, "test", geo]])
  end

  test "insert pointz" do
    geo = %Geo.PointZ{coordinates: {30, -90, 70}, srid: 4326}

    {:ok, _} =
      Ecto.Adapters.SQL.query(
        PostGISRepo,
        "INSERT INTO specified_columns (id, pointz) VALUES ($1, $2)",
        [42, geo]
      )

    {:ok, result} =
      Ecto.Adapters.SQL.query(PostGISRepo, "SELECT id, pointz FROM specified_columns", [])

    assert(result.rows == [[42, geo]])
  end

  test "insert linestring" do
    geo = %Geo.LineString{srid: 4326, coordinates: [{30, 10}, {10, 30}, {40, 40}]}

    {:ok, _} =
      Ecto.Adapters.SQL.query(
        PostGISRepo,
        "INSERT INTO specified_columns (id, linestring) VALUES ($1, $2)",
        [42, geo]
      )

    {:ok, result} =
      Ecto.Adapters.SQL.query(PostGISRepo, "SELECT id, linestring FROM specified_columns", [])

    assert(result.rows == [[42, geo]])
  end

  test "insert LineStringZ" do
    geo = %Geo.LineStringZ{srid: 4326, coordinates: [{30, 10, 20}, {10, 30, 2}, {40, 40, 50}]}

    {:ok, _} =
      Ecto.Adapters.SQL.query(
        PostGISRepo,
        "INSERT INTO specified_columns (id, linestringz) VALUES ($1, $2)",
        [42, geo]
      )

    {:ok, result} =
      Ecto.Adapters.SQL.query(PostGISRepo, "SELECT id, linestringz FROM specified_columns", [])

    assert result.rows == [[42, geo]]
  end

  test "insert LineStringZM" do
    geo = %Geo.LineStringZM{
      srid: 4326,
      coordinates: [{30, 10, 20, 40}, {10, 30, 2, -10}, {40, 40, 50, 100}]
    }

    {:ok, _} =
      Ecto.Adapters.SQL.query(
        PostGISRepo,
        "INSERT INTO specified_columns (id, linestringzm) VALUES ($1, $2)",
        [42, geo]
      )

    {:ok, result} =
      Ecto.Adapters.SQL.query(PostGISRepo, "SELECT id, linestringzm FROM specified_columns", [])

    assert result.rows == [[42, geo]]
  end

  test "insert polygon" do
    geo = %Geo.Polygon{
      coordinates: [
        [{35, 10}, {45, 45}, {15, 40}, {10, 20}, {35, 10}],
        [{20, 30}, {35, 35}, {30, 20}, {20, 30}]
      ],
      srid: 4326
    }

    {:ok, _} =
      Ecto.Adapters.SQL.query(
        PostGISRepo,
        "INSERT INTO specified_columns (id, polygon) VALUES ($1, $2)",
        [42, geo]
      )

    {:ok, result} =
      Ecto.Adapters.SQL.query(PostGISRepo, "SELECT id, polygon FROM specified_columns", [])

    assert(result.rows == [[42, geo]])
  end

  test "insert multipoint" do
    geo = %Geo.MultiPoint{coordinates: [{0, 0}, {20, 20}, {60, 60}], srid: 4326}

    {:ok, _} =
      Ecto.Adapters.SQL.query(
        PostGISRepo,
        "INSERT INTO specified_columns (id, multipoint) VALUES ($1, $2)",
        [42, geo]
      )

    {:ok, result} =
      Ecto.Adapters.SQL.query(PostGISRepo, "SELECT id, multipoint FROM specified_columns", [])

    assert(result.rows == [[42, geo]])
  end

  test "insert multilinestring" do
    geo = %Geo.MultiLineString{
      coordinates: [[{10, 10}, {20, 20}, {10, 40}], [{40, 40}, {30, 30}, {40, 20}, {30, 10}]],
      srid: 4326
    }

    {:ok, _} =
      Ecto.Adapters.SQL.query(
        PostGISRepo,
        "INSERT INTO specified_columns (id, multilinestring) VALUES ($1, $2)",
        [42, geo]
      )

    {:ok, result} =
      Ecto.Adapters.SQL.query(
        PostGISRepo,
        "SELECT id, multilinestring FROM specified_columns",
        []
      )

    assert(result.rows == [[42, geo]])
  end

  test "insert multipolygon" do
    geo = %Geo.MultiPolygon{
      coordinates: [
        [[{40, 40}, {20, 45}, {45, 30}, {40, 40}]],
        [
          [{20, 35}, {10, 30}, {10, 10}, {30, 5}, {45, 20}, {20, 35}],
          [{30, 20}, {20, 15}, {20, 25}, {30, 20}]
        ]
      ],
      srid: 4326
    }

    {:ok, _} =
      Ecto.Adapters.SQL.query(
        PostGISRepo,
        "INSERT INTO specified_columns (id, multipolygon) VALUES ($1, $2)",
        [42, geo]
      )

    {:ok, result} =
      Ecto.Adapters.SQL.query(PostGISRepo, "SELECT id, multipolygon FROM specified_columns", [])

    assert(result.rows == [[42, geo]])
  end
end
