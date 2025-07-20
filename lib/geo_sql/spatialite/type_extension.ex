defmodule GeoSQL.SpatiaLite.TypeExtension do
  @moduledoc """
  A type extension for `ecto_sqlite3` that implements storage and retrieval of
  `geo` structs for Spatialite databases.

  To activate the extension, add this to your `config.exs`:

  ```elixir
    config :ecto_sqlite3,
      extensions: [GeoSQL.Spatialite.TypeExtension]
  ```

  Also be sure to add `load_extensions: ["mod_spatialite"]` to the config of
  `Ecto.Repo`s which use the `Ecto.Adapters.SQLite3` adapter to ensure Spatialite
  features are available.
  """
  @behaviour Ecto.Adapters.SQLite3.TypeExtension
  @behaviour Exqlite.TypeExtension
  @geo_types [
    Geometry.GeometryCollection,
    Geometry.LineString,
    Geometry.LineStringZ,
    Geometry.LineStringM,
    Geometry.LineStringZM,
    Geometry.MultiLineString,
    Geometry.MultiLineStringZ,
    Geometry.MultiLineStringM,
    Geometry.MultiLineStringZM,
    Geometry.MultiPoint,
    Geometry.MultiPointZ,
    Geometry.MultiPointM,
    Geometry.MultiPointZM,
    Geometry.MultiPolygon,
    Geometry.MultiPolygonZ,
    Geometry.MultiPolygonM,
    Geometry.MultiPolygonZM,
    Geometry.Point,
    Geometry.PointZ,
    Geometry.PointM,
    Geometry.PointZM,
    Geometry.Polygon,
    Geometry.PolygonZ,
    Geometry.PolygonM,
    Geometry.PolygonZM
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

  def loaders(_primitive_type, _ecto_type), do: nil

  @impl true
  def dumpers(:geometry, ecto_type) do
    [ecto_type, &__MODULE__.encode_geometry/1]
  end

  def dumpers(:geography, ecto_type) do
    [ecto_type, &__MODULE__.encode_geometry/1]
  end

  def dumpers(_ecto_type, _primitive_type), do: nil

  @impl true
  def convert(%x{} = geometry) when x in @geo_types do
    {:ok, convert_geometry(geometry)}
  end

  def convert(%GeoSQL.QueryUtils.WKB{data: data}) do
    {:ok, {:blob, data}}
  end

  def convert(_), do: nil

  def encode_geometry(%x{} = geometry) when x in @geo_types do
    {:ok, convert_geometry(geometry)}
  rescue
    exception ->
      {:error, exception}
  end

  def decode_geometry(nil), do: {:ok, nil}

  def decode_geometry(data) do
    # it is retrieved in SpatiaLite's format, so translate it to WKB
    conn = InMemorySqlite.conn()

    # prepare the statement; note the use of unhex to get a binary blob out
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "SELECT unhex(AsEWKB(?1))")

    # bind the blob via a :blob tuple
    :ok = Exqlite.Sqlite3.bind(statement, [{:blob, data}])

    # get the response back
    {:row, [ewkb]} = Exqlite.Sqlite3.step(conn, statement)

    # release our resources
    :ok = Exqlite.Sqlite3.release(conn, statement)

    # decode the WKB to a Geo struct
    case Geometry.from_ewkb(ewkb) do
      {:ok, data} -> {:ok, data}
      {:error, _reason} -> :error
    end
  end

  defp convert_geometry(geometry) do
    data =
      Geometry.to_ewkt(geometry)
      |> sanitize_zm_labels()

    # translate it to SpatiaLite's format
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

  # SpatiaLite does not like Z/ZM suffixes on the primitive types.
  # e.g. POINTZ will error, while a POINT with 3-dimensional will work.
  # HOWEVER ... POINTM is a thing. *sigh*
  # Also, Spatialite does not like spaces about the geometry type,
  # despite that being fine by the standard.
  defp sanitize_zm_labels(wkt_encoded_string) do
    wkt_encoded_string
    |> String.replace(~r/\s*ZM?\s*([( ])/, "\\1")
    |> String.replace(~r/\s*([ZM]*)\s*\(/, "\\1(")
  end
end
