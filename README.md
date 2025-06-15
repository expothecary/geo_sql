# GeoSQL

This library provides access to geometry and geography-related SQL functions.

This includes the entire suite of SQL/MM spatial functions,
non-standard functions that are found in commonly used GIS-enabled databases,
implementation-specific functions found in specific backends, as well as high-
level functions for features such as generating Mapbox vector tiles.

The goals of this library are:

 * Ease of use: fast to get started, hides complexity where possible
 * Portable: currently supports PostGIS and SpatialLite.
 * Complete: extensive support for GIS SQL functions, not just the obvious ones.
 * Clarity: Functions organized by their availability and standards compliance
 * Beyond functions: Provide out-of-the-box support for complete worfklows. Mapbox vector tile
   generation is a good example: one call to `GeoSQL.PostGIS.VectorTiles.generate/6`
   is enough to retrieve complete vector tiles based on any table in the database that has a geometry field.

Non-goals include:

 * Having the fewest possible dependencies. Ecto adapters are pulled in as necessary,
   along with other dependencies such as `Jason` needed to ease use.

## Usage

This library is currently not available on `hex.pm`. Until it is, you may add
it to your project by adding the following to the `deps` section in `mix.exs`:

  ```
  {:geo_sql, github: "aseigo/geo_sql"}
  ```

Run the usual `mix deps.get`!

### Readying the Repo with `GeoSQL.init/1`

Once added to your project, an `Ecto.Repo` can be readied for use by calling
`GeoSQL.init/1`. This can be done once the repo has been started by implementing
the `init/2` callback in your repo module like this:

  ```elixir
  defmodule MyApp.Repo do
    use Ecto.Repo,
      otp_app: :my_app,
      adapter: Ecto.Adapters.Postgres

    @impl true
    def init(:supervisor, config) do
      GeoSQL.init(__MODULE__, json: Jason)
      {:ok, config}
    end

    def init(:runtime, config), do: {:ok, config}
  end
  ```

once the repository has been started (usually under a supervisor such as in
`MyApp.Application`). If migrations are failing, place a `GeoSQL.init/1` call
in the top-level of the file the Repo is defined in:

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

`GeoSQL` macros can also be freely composted and used together, such as this query which
uses a number of standard and Postgis-specific features together:

  ```elixir
  from(g in layer.source,
    prefix: ^layer.prefix,
    where:
      bbox_intersects?(
        field(g, ^columns.geometry),
        MM2.transform(tile_envelope(^z, ^x, ^y), ^layer.srid)
      ),
    select: %{
      name: ^layer.name,
      geom:
        as_mvt_geom(
          field(g, ^columns.geometry),
          MM2.transform(tile_envelope(^z, ^x, ^y), ^layer.srid)
        ),
      id: field(g, ^columns.id),
      tags: field(g, ^columns.tags)
    }
  )
  ```

Full documentation can be generated locally with `mix docs`.

### Module organization

Features are organized into modules by their availability and topic.

The v2 and v3 sets of standard SQL/MM functions for geospatial applications are found
in the `GeoSQL.MM2` and `GeoSQL.MM3` modules. Non-standardized but
commonly implemented functions are found in the `GeoSQL.Common` namespace, while
implementation-specific fuctions are found in namespaces indicating the target
database (e.g. `GeoSQL.PostGIS`).

Topological and 3D functions are found in `Topo` and `ThreeD` modules within this
hierarchy, as they less-used and/or have very similar names to more commonly used
SQL functions.

This helps make it clear what features your code relies on, allowing
one to audit feature usage for compability and avoid incompatible use
in the first place.

For example, if you using an older version of `PostGIS`, you may want to stick with only the
functions in the `GeoSQL.MM2` modules as the `GeoSQL.MM3` standard functions were
only implemented in later versions. Similarly, if targeting both `SpatialLite` and
`PostGIS`, the code should only use the standard features plus those in the `GeoSQL.Common`
modules.

To make this even easier, each of the top-level modules supports the `use` syntax which
pulls in their suite of features and introduces helpful aliases with one line in your code:

  ```elixir
  use GeoSQL.MM2
  use GeoSQL.MM3

  def query() do
    from(
      features in MyApp.FeatureLayer,
      select: %{
        area_2d: MM2.area(features.geometry),
        area_3d: MM3.ThreeD.area(features.geometry)
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
    use GeoSQL.PostGIS

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

## Contributing

If you would like to contribute support for more functions (PostGIS and
SpatialLite both provide a frighteningly impressive amount of them!) or
support for other databases, do not hesitate to make a PR and the author
will review and merge in a timely fashion.

## Acknowledgements

This library began as a fork of the excellent `geo_postgis`, which the author
has used for many years. A big thank-you to felt.com for maintaining that
library.

Unfortunately, `geo-postgis` is both PostGIS-specific (as the name correctly
implies), supports functions found in older versions (e.g. pre v3), and is incomplete
in coverage of GIS functions.

This library therefore came into being to scratch the author's itch of a similar
library that has a bit less legacy baggage, can also be used with other databases such
as SpatialLite, and which has additional features such as easy generation of
Mapbox vector tiles directly from the database.
