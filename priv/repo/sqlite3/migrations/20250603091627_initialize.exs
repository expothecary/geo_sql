defmodule GeoSQL.PostGIS.Test.Repo.Migrations.Initialize do
  use Ecto.Migration

  def change do
    execute("SELECT InitSpatialMetadata()", "")

    create table("locations") do
      add(:name, :text)
    end

    execute("SELECT AddGeometryColumn('locations', 'geom', 4326, 'GEOMETRY')", "")

    create table("geographies") do
      add(:name, :text)
    end

    execute("SELECT AddGeometryColumn('geographies', 'geom', 4326, 'GEOMETRY')", "")
    execute("SELECT AddGeometryColumn('geographies', 'line', 4326, 'LINESTRING')", "")

    create table("location_multi") do
      add(:name, :text)
    end

    execute("SELECT AddGeometryColumn('location_multi', 'geom', 4326, 'GEOMETRY')", "")

    create table("specified_columns") do
      add(:t, :text)
    end

    execute("SELECT AddGeometryColumn('specified_columns', 'point', 4326, 'POINT')", "")
    execute("SELECT AddGeometryColumn('specified_columns', 'pointz', 4326, 'POINTZ')", "")

    execute("SELECT AddGeometryColumn('specified_columns', 'linestring', 4326, 'LINESTRING')", "")

    execute(
      "SELECT AddGeometryColumn('specified_columns', 'linestringz', 4326, 'LINESTRINGZ')",
      ""
    )

    execute(
      "SELECT AddGeometryColumn('specified_columns', 'linestringzm', 4326, 'LINESTRINGZM')",
      ""
    )

    execute("SELECT AddGeometryColumn('specified_columns', 'polygon', 4326, 'POLYGON')", "")
    execute("SELECT AddGeometryColumn('specified_columns', 'multipoint', 4326, 'MULTIPOINT')", "")

    execute(
      "SELECT AddGeometryColumn('specified_columns', 'multilinestring', 4326, 'MULTILINESTRING')",
      ""
    )

    execute(
      "SELECT AddGeometryColumn('specified_columns', 'multipolygon', 4326, 'MULTIPOLYGON')",
      ""
    )
  end
end
