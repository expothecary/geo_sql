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

    create table("geographiies") do
      add(:name, :text)
      add(:geom, :geometry)
    end

    create table("location_multi") do
      add(:name, :text)
      add(:geom, :geometry)
    end
  end
end
