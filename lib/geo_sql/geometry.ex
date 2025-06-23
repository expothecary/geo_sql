defmodule GeoSQL.Geometry do
  @moduledoc """
  Geometry types for use with Ecto.
  """

  alias Geo.{
    Point,
    PointZ,
    PointM,
    PointZM,
    LineString,
    LineStringZ,
    LineStringZM,
    Polygon,
    PolygonZ,
    MultiPoint,
    MultiPointZ,
    MultiLineString,
    MultiLineStringZ,
    MultiLineStringZM,
    MultiPolygon,
    MultiPolygonZ,
    GeometryCollection
  }

  @types [
    "Point",
    "PointZ",
    "PointM",
    "PointZM",
    "LineString",
    "LineStringZ",
    "LineStringZM",
    "Polygon",
    "PolygonZ",
    "MultiPoint",
    "MultiPointZ",
    "MultiLineString",
    "MultiLineStringZ",
    "MultiLineStringZM",
    "MultiPolygon",
    "MultiPolygonZ"
  ]

  @geometries [
    Point,
    PointZ,
    PointM,
    PointZM,
    LineString,
    LineStringZ,
    LineStringZM,
    Polygon,
    PolygonZ,
    MultiPoint,
    MultiPointZ,
    MultiLineString,
    MultiLineStringZ,
    MultiLineStringZM,
    MultiPolygon,
    MultiPolygonZ,
    GeometryCollection
  ]

  @type t :: Geo.geometry()

  use Ecto.Type

  def type, do: :geometry

  def blank?(_), do: false

  def load(%struct{} = geom) when struct in @geometries, do: {:ok, geom}

  def load(_data) do
    :error
  end

  def dump(%struct{} = geom) when struct in @geometries, do: {:ok, geom}

  def dump(_data) do
    :error
  end

  def cast({:ok, value}), do: cast(value)

  def cast(%struct{} = geom) when struct in @geometries, do: {:ok, geom}

  def cast(%{"type" => type, "coordinates" => _} = geom) when type in @types do
    do_cast(geom)
  end

  def cast(%{"type" => "GeometryCollection", "geometries" => _} = geom) do
    do_cast(geom)
  end

  def cast(%{type: type, coordinates: _} = geom) when type in @types do
    string_keys(geom)
    |> do_cast()
  end

  def cast(%{type: "GeometryCollection", geometries: _} = geom) do
    string_keys(geom)
    |> do_cast()
  end

  def cast(geom) when is_binary(geom) do
    do_cast(geom)
  end

  def cast(_data) do
    :error
  end

  def string_keys(input_map) when is_map(input_map) do
    Map.new(input_map, fn {key, val} -> {to_string(key), string_keys(val)} end)
  end

  def string_keys(input_list) when is_list(input_list) do
    Enum.map(input_list, &string_keys(&1))
  end

  def string_keys(other), do: other

  defp do_cast(geom) when is_binary(geom) do
    try do
      geom
      |> :json.decode()
      |> do_cast()
    rescue
      error in ErlangError ->
        {:error, [message: "Failed to decode JSON", reason: error.original]}
    end
  end

  defp do_cast(geom) do
    case Geo.JSON.decode(geom) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, [message: "Failed to decode GeoJSON", reason: reason]}
    end
  end

  def embed_as(_), do: :self

  def equal?(a, b), do: a == b
end

for type <- [
      Point,
      PointZ,
      PointM,
      PointZM,
      LineString,
      LineStringZ,
      LineStringZM,
      Polygon,
      PolygonZ,
      MultiPoint,
      MultiPointZ,
      MultiLineString,
      MultiLineStringZ,
      MultiLineStringZM,
      MultiPolygon,
      MultiPolygonZ
    ] do
  defmodule Module.concat(GeoSQL.Geometry, type) do
    @type t :: Geo.geometry()
    use Ecto.Type

    def type, do: unquote(String.to_atom("geo_#{type}"))

    def blank?(_), do: false

    def load(%unquote(Module.concat(Geo, type)){} = geom), do: {:ok, geom}
    def load(_data), do: :error

    def dump(%unquote(Module.concat(Geo, type)){} = geom), do: {:ok, geom}
    def dump(_data), do: :error

    def cast({:ok, value}), do: cast(value)
    def cast(%unquote(Module.concat(Geo, type)){} = geom), do: {:ok, geom}
  end
end
