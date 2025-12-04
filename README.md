# GeoSQL

This library provides access to geometric and geographic SQL functions as
implemented in SQL extensions such as PostGIS and SpatiaLite.

This includes the entire suite of SQL/MM spatial functions,
non-standard functions that are found in commonly used GIS-enabled databases,
implementation-specific functions found in specific backends, as well as high-
level functions for features such as generating Mapbox vector tiles.

The goals of this library are:

 * Ease: fast to get started, hide complexity where possible
 * Portability: currently supports PostGIS and SpatiaLite.
 * Completeness: extensive support for GIS SQL functions, not just the most common ones.
 * Clarity: Functions organized by their availability and standards compliance
 * Utility: Provide out-of-the-box support for complete worfklows. Mapbox vector tile
   generation is a good example: one call to `GeoSQL.PostGIS.VectorTiles.generate/6`
   is enough to retrieve complete vector tiles based on any table in the database that has a geometry field.

Not-goals include:

 * Having the fewest possible dependencies. Ecto adapters are pulled in as necessary,
   along with other dependencies such as `Jason` in order to ease use.

## Usage

Add `GeoSQL` to your project by adding the following to the `deps` section in `mix.exs` (or equivalent):

  ```
  {:geo_sql, "~> 0.1"}
  ```

Run the usual `mix deps.get`!

Full documentation can be generated locally with `mix docs`.

### Ecto Schemas

Ecto Schemas can have fields with the following values:

  * GeoSQL.Geometry: this supports *all* geometry and geography types. It does no typechecking
    beyond confirming it is a Geo-compatible type, making it a perfect "catch-all" generic
    type for use in schemas.
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

  ```elixir
  defmodule MyApp.GeoTable do
    use Ecto.Schema

    schema "specified_columns" do
      field(:name, :string)
      field(:geometry, GeoSQL.Geometry) # will match any Geo type
      field(:point, GeoSQL.Geometry.Point) # will reject any non-Point data
      field(:linestring, GeoSQL.Geometry.LineStringZ) # will reject any non-LineStringZ data
    end
  end
  ```

#### Geopackage

The Geopackage standard defines its own binary format for serializing geometries in SQLite3
databases. GeoSQL provides access to these types via the `GeoSQL.Geometry.Geopackage` type
allowing Ecto schemas to contain geometry fields that are stored as Geopackage data.

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

This schema can now be used in queries like any other:

  ```elixir
  from(g in MyApp.Geopackage) |> MyApp.GeopackageRepo.all()
  ```

Due to being tied to SQLite3, only SQLite3 databases are supported and the Spatialite
module must be available as it is (currently) used to do the serialization in memory.
The Spatialite module does not need to be initialized on a Geopackage database, but
it does need to be available on the system for GeoSQL to use.

### Readying the Repo with `GeoSQL.init/1`

Once added to your project, an `Ecto.Repo` can be readied for use by calling
`GeoSQL.init/2`. This can be done once the repo has been started by implementing
the `init/2` callback in your repo module like this:

  ```elixir
  defmodule MyApp.Repo do
    use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.Postgres

    @impl true
    def init(:supervisor, config) do
      GeoSQL.init(__MODULE__, json: Jason)
      {:ok, config}
    end

    def init(:runtime, config), do: {:ok, config}
  end
  ```

For PostGIS, types are automatically added by `GeoSQL.init/2`. For this reason, call
`GeoSQL.init/2` *after* any other custom types are registered. The type extensions included
in `GeoSQL` are available via the `GeoSQL.PostGIS.Extension.extensions/0` function.

If migrations are failing, place a `GeoSQL.init/1` call in the top-level of the file the Repo is defined in:

  ```
  defmodule MyApp.Repo do
    use Ecto.Repo, otp_app: :geo_sql, adapter: Ecto.Adapters.Postgres
  end

  # For the migrations.
  GeoSQL.init(MyApp.Repo)
  ```

This will ensure that any special types are defined and registered, though it
will still need to be called after the repo has been started.

Dynamic Ecto repositories are also supported, and `GeoSQL.init/1` can be
called after the call to `Repo.put_dynamic_repo/1` has completed.

### Macro usage

Once initialized, the wide array of macros can be used with `Ecto` queries:

  ```elixir
  from(location in Location, select: Common.extent(location.geom, MyApp.Repo))
  ```

Some macros, such as `GeoSQL.Common.extent`, take an optional `Ecto.Repo` parameter.
This allows those macros to generate the correct SQL statements for the backend being used.
If no repo is passed to those functions, they assume PostGIS compatibility by default, though
this can be configured by adding this to `config.ex`:

  ```elixir
  config :geo_sql, default_adapter: Ecto.Adapters.<PreferredAdapter>
  ```

Note that the value passed must be the literal repo module name. Passing in a variable
to which the repo was assigned will usually fail unless wrapped in a macro context, as
Ecto does all of its magic at compile-time, making the value of runtime variables unnavailable
for constructing queries (which is different from populating them with values). Usually this is
not an issue.

#### Composition

`GeoSQL` macros can also be freely composted and used together, such as this query which
uses a number of standard and PostGIS-specific features together:

  ```elixir
  from(g in layer.source,
    prefix: ^layer.prefix,
    where:
      bbox_intersects?(
        field(g, ^columns.geometry),
        MM.transform(tile_envelope(^z, ^x, ^y), type(^layer.srid, Int4))
      ),
    select: %{
      name: ^layer.name,
      geom:
        as_mvt_geom(
          field(g, ^columns.geometry),
          MM.transform(
            tile_envelope(^z, ^x, ^y),
            type(^layer.srid, Int4)
          )
        ),
      id: field(g, ^columns.id),
      tags: field(g, ^columns.tags)
    }
  )
  ```

#### Queries needing geometry type casting

Sometimes queries will require casting to the database's native geometry type. Such casting is backend-specific, and so the `GeoSQL.QueryUtils.cast_to_geometry/2`
function which takes an `Ecto.Repo` is provided for portability.

The need to use it  occurs when, for example, a query passes a geography type to a geometry
function in PostGIS, or the adapter (e.g. `postgrex`) can not automatically determine the type.
A common symptom of the latter case are errors noting that a binary was expected, and
the geometry struct provided was not serialized.

For example this query, where `lineA` and `lineB` are `Geometry.LineString` structs:

  ```elixir
  from(location in Locations, select: MM.intersection(^lineA, ^lineB))
  ```

may produce this error:

  ```
  Postgrex expected a binary, got %Geometry.LineString{path: [[30, -90], [30, -91]], srid: 4326}. Please make sure the value you are passing matches the definition in your table or in your query or convert the value accordingly.
  ```

Casting one of the two type is usually enough to resolve this:


  ```elixir
  from(location in Locations, select: MM.intersection(QueryUtils.cast_to_geometry(^lineA, MyApp.Repo), ^lineB))
  ```

Note that using Ecto Schemas or referencing columns from a table avoids these issues, as the
database adapters can determine what the correct types are from that information.

### Queries Taking WKB data

Some functions take WKB-encoded data. If passing WKB blobs from the client-side to the backend,
wrap them using the `QueryUtils.wrap_wkb/2` macro, passing in the Ecto repo as the second parameter.

When used in a query, the return of this macro will need to be pinned (`^`) as it returns a value.

Example:


  ```elixir
  from(g in GeoType,
    select: g.linestring == MM.linestring_from_wkb(^QueryUtils.wrap_wkb(wkb, MyApp.Repo), ^line.srid)
  )
  ```

### Queries returning binary blobs instead of geometries

With certain backends (e.g. SQLite3), it is possible to craft queries that will return
binary blobs instead of decoded `Geo` structs.

In such cases, use `GeoSQL.QueryUtils.decode_geometry/2`:

  ```elixir
  defmodule MyApp.Plots do
    use GeoSQL.MM
    use GeoSQL.QueryUtils

    def boundaries() do
      from(location in Location, select: MM.boundary(location.geom))
      |> Repo.all()
      |> QueryUtils.decode_geometry(Repo)
    end
  end
  ```

For backends that do not suffer from this (e.g. PostGIS), the call to `GeoSQL.decode_geometry`
is efficient, doing little more than a comparison of a single `atom` to determine no further
action needs to be taken.

### Module organization

Features are organized into modules by their availability and topic.

The v2 and v3 sets of standard SQL/MM functions for geospatial applications are found
in the `GeoSQL.MM`module. Non-standardized but commonly implemented functions are found in the `GeoSQL.Common` namespace, while implementation-specific fuctions are found in namespaces indicating the target database (e.g. `GeoSQL.PostGIS`).

Topological and 3D functions are found in `Topo` and `ThreeD` modules within this
hierarchy, as they less-used and/or have very similar names to more commonly used
SQL functions.

This helps make it clear what features your code relies on, allowing
one to audit feature usage for compability and avoid incompatible use
in the first place.

For example, if targeting both `SpatiaLite` and `PostGIS`, the code should only use the standard SQL/MM features plus those in the `GeoSQL.Common` modules.

To make this even easier, each of the top-level modules supports the `use` syntax which
pulls in their suite of features and introduces helpful aliases with one line in your code:

  ```elixir
  use GeoSQL.MM

  def query() do
    from(features in MyApp.Feature
      select: %{
        area_2d: MM.area(features.geometry)`
        area_3d: MM.ThreeD.area(features.geometry)
      }
    )
  end

  ```

### Mapbox Vector Tiles

`GeoSQL` can generate vector tiles using the Mapbox encoding directly from PostGIS databases.
It works with any table that has an id column, a column with geometry information, and a set of
tagged information such as names. The tag information is usually fetch as (or from) a `jsonb` data.

The `PostGIS.VectorTiles.generate/5` function takes a layer definition in the form of a list of
`PostGIS.VectorTiles.Layer` structs along with the tile coordinates and an `Ecto.Repo`:

  ```elixir
  def tile(zoom, x, y) do
    layers = [
      %PostGIS.VectorTiles.Layer{
        name: "pois",
        source: "nodes",
        columns: %{geometry: :geom, id: :node_id, tags: :tags}
      },
      %PostGIS.VectorTiles.Layer{
        name: "buildings",
        source: "buildings",
        columns: %{geometry: :footprint, id: :id, tags: :tags}
      }
    ]


    PostGIS.VectorTiles.generate(MyApp.Repo, zoom, x, y, layers)
  end
  ```

The resulting data can be loaded directly into map renderers such as `MapLibre` or `OpenLayers`
with the `MVT` vector tile layer format.

Database prefixes ("schemas" in PostgreSQL) are also supported both on the whole tile query
as well as per-layer.

## Building

To build and interact with the library locally:

    git clone https://github.com/aseigo/geo_sql.git
    cd geo_sql
    mix deps.get
    mix compile
    iex -S mix


## Unit Tests

Unit tests currently assume a working PostGIS installation is available locally.

The URL for the test database is defined in `config/test.exs`.

**Note** that this database will be created and **dropped** on every run of the tests.
Do NOT point it to an existing database!

The migrations in `priv/repo/migrations` are run on each test run.

Running `mix test` will run tests along with setting up and tearing down the database.
This allows the tests to access the database in a known state each run.

Tests may be run continuously with `mix test.watch`.

### Running tests for a subset of backends

To limit which backends the tests are run against, set the `GEOSQL_TEST_BACKENDS` environment variable before running tests to a comma-separated list of backends.

Example:

  ```shell
  # Run only the PostGIS tests.
  GEOSQL_TEST_BACKENDS=pgsql mix test test/ecto_test.exs
  ```

Current the following backends are recognized:

  * `pgsql`
  * `sqlite3`

## Contributing

If you would like to contribute support for more functions (PostGIS and
SpatiaLite both provide a frighteningly impressive amount of them!) or
support for other databases, do not hesitate to make a PR and the author
will review and merge in a timely fashion.

## Acknowledgements

This library began as a fork of the excellent `geo_postgis`, which the author
has used for many years, before growing into something rather larger. A big thank-you to felt.com for maintaining that
library over the course of many years.
