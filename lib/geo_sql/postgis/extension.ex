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
