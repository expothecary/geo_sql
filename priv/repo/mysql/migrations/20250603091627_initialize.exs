defmodule GeoSQL.MySQL.Test.Repo.Migrations.Initialize do
  use Ecto.Migration

  def change do
    create table("locations") do
      add(:name, :text)
      add(:geom, :geometry)
    end

    create table("geographies") do
      add(:name, :text)
      add(:geom, :geometry)
      add(:line, :geometry)
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
          point geometry(4326),
          pointz geometry(4326),
          linestring geometry(4326),
          linestringm geometry(4326),
          linestringz geometry(4326),
          linestringzm geometry(4326),
          polygon geometry(4326),
          polygonm geometry(4326),
          multipoint geometry(4326),
          multilinestring geometry(4326),
          multipolygon geometry(4326)
        )
      ",
      "DROP TABLE specified_columns"
    )
  end
end
