defmodule GeoSQL.PostGIS.Test.Repo.Migrations.Initialize do
  use Ecto.Migration

  def change do
    execute(
      "CREATE EXTENSION IF NOT EXISTS postgis",
      "DROP EXTENSION IF EXISTS postgis"
    )

    create table("locations") do
      add(:name, :text)
      add(:geom, :geometry)
    end

    create table("geographies") do
      add(:name, :text)
      add(:geom, :geography)
      add(:line, :geography)
    end

    create table("location_multi") do
      add(:name, :text)
      add(:geom, :geometry)
    end

    execute(
      "CREATE TABLE specified_columns
        (
          id int,
          t  text,
          point geometry(Point, 4326),
          pointz geometry(PointZ, 4326),
          linestring geometry(Linestring, 4326),
          linestringz geometry(LineStringZ, 4326),
          linestringm geometry(LineStringM, 4326),
          linestringzm geometry(LineStringZM, 4326),
          polygon geometry(Polygon, 4326),
          polygonm geometry(PolygonM, 4326),
          multipoint geometry(MultiPoint, 4326),
          multilinestring geometry(MultiLinestring, 4326),
          multipolygon geometry(MultiPolygon, 4326)
        )
      ",
      "DROP TABLE specified_columns"
    )

    execute("CREATE SCHEMA map")

    create table("vector_tile_pois") do
      add(:tags, :map, default: %{}, null: false)
      add(:geom, :"geometry(Point, 4326)")
    end

    create table("vector_tile_pois", prefix: "map") do
      add(:tags, :map, default: %{}, null: false)
      add(:geom, :"geometry(Point, 4326)")
    end
  end
end
