defmodule GeoSQL.PostGIS.Extension do
  @moduledoc """
  A type extension for PostGIS data in PostgreSQL databases.

  Automatically applied when a PostgreSQL Ecto repo is passed into `GeoSQL.init/2`.
  """
  @behaviour Postgrex.Extension

  @doc "Convenience function to get the extension modules for PostGIS support."
  def extensions do
    [__MODULE__]
  end

  @doc false
  def init(_opts), do: nil

  @doc false
  def matching(_), do: [type: "geometry", type: "geography"]

  @doc false
  def format(_), do: :binary

  @doc false
  def encode(_opts) do
    all_types =
      unquote(GeoSQL.Geometry.all_types())

    quote do
      %x{} = geom when x in unquote(all_types) ->
        data = Geometry.to_ewkb(geom)
        [<<IO.iodata_length(data)::integer-size(32)>> | data]
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
