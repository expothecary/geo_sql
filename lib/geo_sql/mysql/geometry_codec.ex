if Code.ensure_loaded?(MyXQL) do
  defmodule GeoSQL.MySQL.GeometryCodec do
    @behaviour MyXQL.Protocol.GeometryCodec

    supported_structs = [
      Geometry.Point,
      Geometry.GeometryCollection,
      Geometry.LineString,
      Geometry.MultiPoint,
      Geometry.MultiLineString,
      Geometry.MultiPolygon,
      Geometry.Polygon
    ]

    def encode(%x{} = geo) when x in unquote(supported_structs) do
      srid = geo.srid || 0
      wkb = Geometry.to_wkb(geo, :ndr)
      {srid, wkb}
    end

    def encode(_), do: :unknown

    def decode(0, wkb), do: Geometry.from_wkb!(wkb)
    def decode(srid, wkb), do: Geometry.from_wkb!(wkb) |> Map.put(:srid, srid)
  end
end
