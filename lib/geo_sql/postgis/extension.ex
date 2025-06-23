defmodule GeoSQL.PostGIS.Extension do
  @moduledoc false
  @behaviour Postgrex.Extension

  def extensions do
    unquote(
      Enum.reduce(
        GeoSQL.Geometry.all_types(),
        [__MODULE__],
        fn type, acc ->
          [Module.concat(__MODULE__, type) | acc]
        end
      )
    )
  end

  def init(_opts), do: nil

  def matching(_), do: [type: "geometry", type: "geography"]

  def format(_), do: :binary

  def encode(_opts) do
    all_types = unquote(GeoSQL.Geometry.all_types())

    quote location: :keep do
      %x{} = geom when x in unquote(all_types) ->
        data = Geo.WKB.encode_to_iodata(geom)
        [<<IO.iodata_length(data)::integer-size(32)>> | data]
    end
  end

  def decode(_opts) do
    quote location: :keep do
      <<len::integer-size(32), wkb::binary-size(len)>> ->
        Geo.WKB.decode!(wkb)
    end
  end
end

for type <- GeoSQL.Geometry.all_types() do
  defmodule Module.concat(GeoSQL.PostGIS.Extension, type) do
    def init(_), do: nil

    def matching(_),
      do: [
        type:
          unquote(Module.split(type) |> Enum.intersperse("_") |> to_string() |> String.downcase())
      ]

    def format(_), do: :binary

    def encode(_) do
      type = unquote(type)

      quote location: :keep do
        %x{} = geom when x == unquote(type) ->
          data = Geo.WKB.encode_to_iodata(geom)
          [<<IO.iodata_length(data)::integer-size(32)>> | data]
      end
    end

    def decode(_opts) do
      type = unquote(type)

      quote location: :keep do
        <<len::integer-size(32), wkb::binary-size(len)>> ->
          %x{} = decoded = Geo.WKB.decode!(wkb)

          if x != unquote(type), do: nil, else: decoded
      end
    end
  end
end
