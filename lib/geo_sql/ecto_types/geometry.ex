defmodule GeoSQL.Geometry do
  @moduledoc """
  Geometry types for use with ecto. Supported types include:

    * GeoSQL.Geometry, a catch-all type
    * GeoSQL.Geometry.Geopackage, a catch-all type for fields containing Geopackage geometry blobs
    * GeoSQL.Geometry.Point
    * GeoSQL.Geometry.PointZ
    * GeoSQL.Geometry.PointM
    * GeoSQL.Geometry.PointZM
    * GeoSQL.Geometry.LineString
    * GeoSQL.Geometry.LineStringZ
    * GeoSQL.Geometry.LineStringZM
    * GeoSQL.Geometry.Polygon
    * GeoSQL.Geometry.PolygonZ
    * GeoSQL.Geometry.MultiPoint
    * GeoSQL.Geometry.MultiPointZ
    * GeoSQL.Geometry.MultiLineString
    * GeoSQL.Geometry.MultiLineStringZ
    * GeoSQL.Geometry.MultiLineStringZM
    * GeoSQL.Geometry.MultiPolygon
    * GeoSQL.Geometry.MultiPolygonZ
    * GeoSQL.Geometry.GeometryCollection

  Example:

      defmodule MyApp.GeoTable do
        use Ecto.Schema

        schema "specified_columns" do
          field(:name, :string)
          field(:geometry, GeoSQL.Geometry) # will match any Geo type
          field(:point, GeoSQL.Geometry.Point) # will reject any non-Point data
          field(:linestring, GeoSQL.Geometry.LineStringZ) # will reject any non-LineStringZ data
        end
      end
  """

  alias Geometry.{
    Point,
    PointZ,
    PointM,
    PointZM,
    LineString,
    LineStringZ,
    LineStringM,
    LineStringZM,
    Polygon,
    PolygonZ,
    PolygonM,
    PolygonZM,
    MultiPoint,
    MultiPointZ,
    MultiPointM,
    MultiPointZM,
    MultiLineString,
    MultiLineStringZ,
    MultiLineStringM,
    MultiLineStringZM,
    MultiPolygon,
    MultiPolygonZ,
    MultiPolygonM,
    MultiPolygonZM,
    GeometryCollection,
    GeometryCollectionZ,
    GeometryCollectionM,
    GeometryCollectionZM
  }

  @types [
    "Point",
    "PointZ",
    "PointM",
    "PointZM",
    "LineString",
    "LineStringZ",
    "LineStringM",
    "LineStringZM",
    "Polygon",
    "PolygonZ",
    "PolygonM",
    "PolygonZM",
    "MultiPoint",
    "MultiPointZ",
    "MultiPointM",
    "MultiPointZM",
    "MultiLineString",
    "MultiLineStringZ",
    "MultiLineStringM",
    "MultiLineStringZM",
    "MultiPolygon",
    "MultiPolygonZ",
    "MultiPolygonM",
    "MultiPolygonZM"
  ]

  @geometries [
    Point,
    PointZ,
    PointM,
    PointZM,
    LineString,
    LineStringZ,
    LineStringM,
    LineStringZM,
    Polygon,
    PolygonZ,
    PolygonM,
    PolygonZM,
    MultiPoint,
    MultiPointZ,
    MultiPointM,
    MultiPointZM,
    MultiLineString,
    MultiLineStringZ,
    MultiLineStringM,
    MultiLineStringZM,
    MultiPolygon,
    MultiPolygonZ,
    MultiPolygonM,
    MultiPolygonZM,
    GeometryCollection,
    GeometryCollectionZ,
    GeometryCollectionM,
    GeometryCollectionZM
  ]

  @type t :: Geometry.t()

  use Ecto.Type

  @spec from_db_type(db_type :: String.t()) :: t()
  @doc """
  Returns the matching Geometry type for a geometry type returned from the database
  """
  def from_db_type("ST_" <> type), do: from_db_type(type)

  def from_db_type(db_type) when is_binary(db_type) do
    case String.downcase(db_type) do
      "point" <> _rest -> Point
      "linestring" <> _rest -> LineString
      "polygon" <> _rest -> Polygon
      "multipoint" <> _rest -> MultiPoint
      "multilinestring" <> _rest -> MultiLineString
      "multipolygon" <> _rest -> MultiPolygon
      "geometrycollection" <> _rest -> GeometryCollection
    end
  end

  @doc false
  def geometry_modules do
    Enum.map(
      @geometries,
      fn type -> GeoSQL.Geometry.create_geometry_module_name(type) end
    )
  end

  @doc false
  def all_types, do: @geometries

  @doc false
  def type, do: :geometry

  @doc false
  def blank?(_), do: false

  @doc false
  def load(%struct{} = geom) when struct in @geometries, do: {:ok, geom}

  def load(_data) do
    :error
  end

  @doc false
  def dump(%struct{} = geom) when struct in @geometries, do: {:ok, geom}

  def dump(_data) do
    :error
  end

  @doc false
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

  @doc false
  def string_keys(input_map) when is_map(input_map) do
    Map.new(input_map, fn {key, val} -> {to_string(key), string_keys(val)} end)
  end

  def string_keys(input_list) when is_list(input_list) do
    Enum.map(input_list, &string_keys(&1))
  end

  def string_keys(other), do: other

  @doc false
  def embed_as(_), do: :self

  @doc false
  def equal?(a, b), do: a == b

  @doc false
  def create_geometry_module_name(type) do
    ["Geometry", subtype] = Module.split(type)
    Module.concat(GeoSQL.Geometry, subtype)
  end

  defp do_cast(geom) when is_binary(geom) do
    try do
      geom
      |> JSON.decode!()
      |> do_cast()
    rescue
      error in ErlangError ->
        {:error, [message: "Failed to decode JSON", reason: error.original]}
    end
  end

  defp do_cast(geom) do
    case Geometry.from_geo_json(geom) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, [message: "Failed to decode GeoJSON", reason: reason]}
    end
  end
end

defmodule GeoSQL.Geometry.Geopackage do
  # This is just GeoSQL.Geometry in a Geopackage costume
  # It allows type systems to differentiate beteween standard
  # geometry encodings and Geopackage encoding.
  @moduledoc """
  A Geopackage data type for use with geopackage-encoded fields

  Example:

    ```elixir
    defmodule MyApp.Geopackage do
      use Ecto.Schema

      @primary_key false
      schema "some_table_in_geopackage" do
        field(:id, :integer, source: :OBJECTID)
        field(:name, :string)
        field(:shape, GeoSQL.Geometry.Geopackage, source: :Shape)
      end
    end
    ```

  The schema can now be used in queries like any other:

    ```elixir
    from(g in MyApp.Geopackage) |> MyApp.GeopackageRepo.all()
    ```
  """

  @type t :: Geometry.t()
  use Ecto.Type

  def type, do: :geopackage_geometry
  def blank?(_), do: false
  defdelegate load(geom), to: GeoSQL.Geometry
  defdelegate dump(geom), to: GeoSQL.Geometry
  defdelegate cast(value), to: GeoSQL.Geometry
  defdelegate embed_as(value), to: GeoSQL.Geometry
  defdelegate equal?(a, b), to: GeoSQL.Geometry
end

for type <- GeoSQL.Geometry.all_types() do
  module_name = GeoSQL.Geometry.create_geometry_module_name(type)

  # e.g. GeoSQL.Geometry.Point or GeoSQL.Geometry.LinestringZM
  defmodule module_name do
    @moduledoc false
    @type t :: %unquote(type){}
    use Ecto.Type

    def type, do: :geometry

    def blank?(_), do: false

    def load(%unquote(type){} = geom), do: {:ok, geom}
    def load(_data), do: :error

    def dump(%unquote(type){} = geom), do: {:ok, geom}
    def dump(_data), do: :error

    def cast({:ok, value}), do: cast(value)
    def cast(%unquote(type){} = geom), do: {:ok, geom}

    def embed_as(_), do: :self

    def equal?(a, b), do: a == b
  end
end

if Code.ensure_loaded?(Geo) and not Code.ensure_loaded?(Geo.PostGIS.Geometry) do
  defmodule Geo.PostGIS.Geometry do
    @moduledoc false

    alias Geo.{
      Point,
      PointZ,
      PointM,
      PointZM,
      LineString,
      LineStringM,
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
      "LineStringM",
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
      LineStringM,
      LineStringZ,
      LineStringZM,
      Polygon,
      PolygonZ,
      MultiPoint,
      MultiPointZ,
      MultiLineString,
      MultiLineStringM,
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

    def cast(_), do: :error

    def string_keys(input_map) when is_map(input_map) do
      Map.new(input_map, fn {key, val} -> {to_string(key), string_keys(val)} end)
    end

    def string_keys(input_list) when is_list(input_list) do
      Enum.map(input_list, &string_keys(&1))
    end

    def string_keys(other), do: other

    defp do_cast(geom) when is_binary(geom) do
      case JSON.decode!(geom) do
        {:ok, geom} when is_map(geom) -> do_cast(geom)
        {:error, reason} -> {:error, [message: "failed to decode JSON", reason: reason]}
      end
    end

    defp do_cast(geom) do
      case JSON.decode!(geom) do
        {:ok, result} -> {:ok, result}
        {:error, reason} -> {:error, [message: "failed to decode GeoJSON", reason: reason]}
      end
    end

    def embed_as(_), do: :self

    def equal?(a, b), do: a == b
  end
end
