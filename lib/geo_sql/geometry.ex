defmodule GeoSQL.Geometry do
  @moduledoc false

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

  if macro_exported?(Ecto.Type, :__using__, 1) do
    use Ecto.Type
  else
    @behaviour Ecto.Type
  end

  def type, do: :geometry

  def blank?(_), do: false

  def load(%struct{} = geom) when struct in @geometries, do: {:ok, geom}
  def load(_), do: :error

  def dump(%struct{} = geom) when struct in @geometries, do: {:ok, geom}
  def dump(_), do: :error

  def cast({:ok, value}), do: cast(value)

  def cast(%struct{} = geom) when struct in @geometries, do: {:ok, geom}

  def cast(%{"type" => type, "coordinates" => _} = geom) when type in @types do
    do_cast(geom)
  end

  def cast(%{"type" => "GeometryCollection", "geometries" => _} = geom) do
    do_cast(geom)
  end

  def cast(geom) when is_binary(geom) do
    do_cast(geom)
  end

  def cast(_), do: :error

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
