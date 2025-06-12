# GeoSQL

This library provides access to geometry and geography-related SQL functions.

This includes the entire suite of SQL/MM spatial functions as well as
non-standard functions that are found in commonly used GIS-enabled databases.

Implementation-specific functions are collected in modules, such as the
`GeoSQL.PostGIS` module.

## Use

This library is currently not available on `hex.pm`. Until it is, you may add
it to your project by adding the following to the `deps` section in `mix.exs`:

  `{:geo_sql, github: "aseigo/geo_sql"}`

Documentation is in progress as well, though generally available as standard
module docs which can be generated locally with `mix docs`.

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
