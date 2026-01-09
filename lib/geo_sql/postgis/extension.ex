defmodule GeoSQL.PostGIS.Extension.Box2D do
  @moduledoc false
  @doc false
  def init(_opts), do: nil

  @behaviour Postgrex.Extension
  @doc false
  def matching(_opts), do: [type: "box2d"]

  @doc false
  def format(_opts), do: :text

  @doc false
  def encode(_opts) do
    quote do
      %GeoSQL.PostGIS.Box2D{} = box ->
        string = "BOX(#{box.xmin} #{box.ymin}, #{box.xmax} #{box.ymax})"
        [<<IO.iodata_length(string)::integer-size(32)>>, string]
    end
  end

  @doc false
  def decode(_opts) do
    quote do
      <<len::integer-size(32), "BOX(", coords::binary-size(len - 5), ")">> ->
        [top_left, bottom_right] = String.split(coords, ",", parts: 2)

        [string_x1, string_y1] = String.split(top_left, " ", parts: 2)
        {xmin, ""} = Float.parse(string_x1)
        {ymin, ""} = Float.parse(string_y1)

        [string_x2, string_y2] = String.split(bottom_right, " ", parts: 2)
        {xmax, ""} = Float.parse(string_x2)
        {ymax, ""} = Float.parse(string_y2)

        %GeoSQL.PostGIS.Box2D{xmin: xmin, ymin: ymin, xmax: xmax, ymax: ymax}
    end
  end
end

defmodule GeoSQL.PostGIS.Extension do
  @moduledoc """
  A type extension for PostGIS data in PostgreSQL databases.

  Automatically applied when a PostgreSQL Ecto repo is passed into `GeoSQL.init/2`.
  """
  @behaviour Postgrex.Extension

  # import __MODULE__.Macros
  @doc "Convenience function to get the extension modules for PostGIS support."
  def extensions do
    [__MODULE__, __MODULE__.Box2D]
  end

  @doc false
  def init(_opts), do: nil

  @doc false
  def matching(_opts), do: [type: "geometry", type: "geography"]

  @doc false
  def format(_opts), do: :binary

  if Code.ensure_loaded?(Geo) do
    def encode_geo(geom) do
      data = Geo.WKB.encode_to_iodata(geom)
      [<<IO.iodata_length(data)::integer-size(32)>> | data]
    end
  else
    def encode_geo(%x{}) do
      raise "GeoSQL PostGIS Extension can not encode #{x} without the geo library."
    end
  end

  @doc false
  def encode(_opts) do
    all_geometry_types = unquote(GeoSQL.Geometry.all_types())

    all_geo_types = [
      Geo.GeometryCollection,
      Geo.LineString,
      Geo.LineStringM,
      Geo.LineStringZ,
      Geo.LineStringZM,
      Geo.MultiLineString,
      Geo.MultiLineStringM,
      Geo.MultiLineStringZ,
      Geo.MultiLineStringZM,
      Geo.MultiPoint,
      Geo.MultiPointZ,
      Geo.MultiPolygon,
      Geo.MultiPolygonZ,
      Geo.Point,
      Geo.PointZ,
      Geo.PointM,
      Geo.PointZM,
      Geo.Polygon,
      Geo.PolygonZ
    ]

    quote do
      %x{} = geom when x in unquote(all_geometry_types) ->
        data = Geometry.to_ewkb(geom)
        [<<IO.iodata_length(data)::integer-size(32)>> | data]

      %x{} = geom when x in unquote(all_geo_types) ->
        IO.inspect(x, label: "GOT A GEO TYPE!")
        GeoSQL.PostGIS.Extension.encode_geo(geom)
    end
  end

  @doc false
  def decode(_opts) do
    quote do
      <<len::integer-size(32), wkb::binary-size(len)>> ->
        {:ok, decoded} = Geometry.from_ewkb(wkb)
        decoded
    end
  end
end
