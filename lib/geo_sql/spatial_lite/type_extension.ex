defmodule GeoSQL.SpatialLite.TypeExtension do
  @moduledoc """
  A type extension for `ecto_sqlite3` that implements storage and retrieval of
  `geo` structs for SpatialLite databases.

  To activate the extension, add this to your `config.exs`:

  ```elixir
    config :ecto_sqlite3,
      extensions: [GeoSQL.SpatialLite.TypeExtension]
  ```

  Also be sure to add `load_extensions: ["mod_spatialite"]` to the config of
  `Ecto.Repo`s which use the `Ecto.Adapters.SQLite3` adapter to ensure SpatialLite
  features are available.
  """
  @behaviour Ecto.Adapters.SQLite3.TypeExtension
  @behaviour Exqlite.TypeExtension
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

  defmodule InMemorySqlite do
    @moduledoc false
    use Agent

    def start_link() do
      Agent.start_link(&start_conn/0, name: __MODULE__)
    end

    def start() do
      Agent.start(&start_conn/0, name: __MODULE__)
    end

    def start_conn() do
      {:ok, conn} = Exqlite.Sqlite3.open(":memory:")
      Exqlite.Sqlite3.enable_load_extension(conn, true)
      Exqlite.Sqlite3.execute(conn, "select load_extension('mod_spatialite')")
      conn
    end

    def conn do
      if Process.whereis(__MODULE__) == nil do
        __MODULE__.start()
      end

      Agent.get(__MODULE__, & &1)
    end
  end

  @impl true
  def loaders(:geometry, ecto_type) do
    [&__MODULE__.decode_geometry/1, ecto_type]
  end

  def loaders(:geography, ecto_type) do
    [&__MODULE__.decode_geometry/1, ecto_type]
  end

  for module <- GeoSQL.Geometry.geometry_modules() do
    type = module.type()

    def loaders(unquote(type), ecto_type) do
      [&__MODULE__.decode_geometry/1, ecto_type]
    end
  end

  def loaders(_primitive_type, _ecto_type), do: nil

  @impl true
  def dumpers(:geometry, ecto_type) do
    [ecto_type, &__MODULE__.encode_geometry/1]
  end

  def dumpers(:geography, ecto_type) do
    [ecto_type, &__MODULE__.encode_geometry/1]
  end

  for module <- GeoSQL.Geometry.geometry_modules() do
    type = module.type()

    def dumpers(unquote(type), ecto_type) do
      [ecto_type, &__MODULE__.encode_geometry/1]
    end
  end

  def dumpers(_ecto_type, _primitive_type), do: nil

  @impl true
  def convert(%x{} = geometry) when x in @geo_types do
    {:ok, convert_geometry(geometry)}
  end

  def convert(_), do: nil

  def encode_geometry(%x{} = geometry) when x in @geo_types do
    {:ok, convert_geometry(geometry)}
  rescue
    exception ->
      {:error, exception}
  end

  def decode_geometry(data) do
    # it is retrieved in SpatialLite's format, so translate it to WKB
    conn = InMemorySqlite.conn()
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "SELECT AsEWKB(?1)")
    :ok = Exqlite.Sqlite3.bind(statement, [{:blob, data}])
    {:row, [wkb]} = Exqlite.Sqlite3.step(conn, statement)
    :ok = Exqlite.Sqlite3.release(conn, statement)

    # decode the WKB to a Geo struct
    case Geo.WKB.decode(wkb) do
      {:ok, data} -> {:ok, data}
      {:error, _reason} -> :error
    end
  end

  defp convert_geometry(geometry) do
    data =
      Geo.WKT.encode(geometry)
      |> remove_zm_labels()

    # translate it to SpatialLite's format
    conn = InMemorySqlite.conn()
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "SELECT GeomFromEWKT(?1)")
    :ok = Exqlite.Sqlite3.bind(statement, [data])
    {:row, [encoded]} = Exqlite.Sqlite3.step(conn, statement)
    :ok = Exqlite.Sqlite3.release(conn, statement)

    case encoded do
      nil -> nil
      _ -> {:blob, encoded}
    end
  end

  # SpatialLite does not like Z/ZM suffixes on the primitive types.
  # e.g. POINTZ will error, while a POINT with 3-dimensional will work.
  # HOWEVER ... POINTM is a thing. *sigh*
  defp remove_zm_labels({:ok, wkt_encoded_string}) do
    wkt_encoded_string
    |> String.replace(~r/ZM?([( ])/, "\\1")
  end
end
