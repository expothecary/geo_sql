defmodule GeoSQL.PostGIS.Extension do
  @moduledoc """
  PostGIS extension for Postgrex. Supports Geometry and Geography data types.

  ## Examples

  Create a new Postgrex Types module:

      Postgrex.Types.define(MyApp.PostgresTypes, [GeoSQL.Extension], [])

  If using with Ecto, you may want something like thing instead:

      Postgrex.Types.define(MyApp.PostgresTypes,
                    [GeoSQL.Extension] ++ Ecto.Adapters.Postgres.extensions())

  By default, the extension works on a copy of the binary data received. By passing
  `decode_binary: :reference` as an option, it will instead not copy the binary that is used to
  populate the types. While faster, this can have side-effects such as large binaries
  remaining in memory due to ref-counting for longer than one might way. As such, it
  is recommended to change this option only after testing.

  Normally one does not need to add the types directly, as type registration is handled
  automatically by `GeoSQL.init/1`.
  """

  @behaviour Postgrex.Extension

  @geo_types [
    Geo.GeometryCollection,
    Geo.LineString,
    Geo.LineStringZ,
    Geo.LineStringZM,
    Geo.MultiLineString,
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

  def init(opts) do
    Keyword.get(opts, :decode_copy, :copy)
  end

  def matching(_) do
    [type: "geometry", type: "geography"]
  end

  def format(_) do
    :binary
  end

  def encode(_opts) do
    quote location: :keep do
      %x{} = geom when x in unquote(@geo_types) ->
        data = Geo.WKB.encode_to_iodata(geom)
        [<<IO.iodata_length(data)::integer-size(32)>> | data]
    end
  end

  def decode(:reference) do
    quote location: :keep do
      <<len::integer-size(32), wkb::binary-size(len)>> ->
        Geo.WKB.decode!(wkb)
    end
  end

  def decode(:copy) do
    quote location: :keep do
      <<len::integer-size(32), wkb::binary-size(len)>> ->
        Geo.WKB.decode!(:binary.copy(wkb))
    end
  end
end
