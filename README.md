# GeoSQL

This library provides access to geometry and geography-related SQL functions.

This includes the entire suite of SQL/MM spatial functions as well as
non-standard functions that are found in commonly used GIS-enabled databases.

Implementation-specific functions are collected in modules, such as the
`GeoSQL.PostGIS` module.

## Acknowledgements

This library began as a fork of the excellent `geo_postgis`, which the author
has used for many years. A big thank-you to felt.com for maintaining that
library.

Unfortunately, `geo-postgis` is both PostGIS-specific, supports functions as
found in older versions (pre v3), and is incomplete. This library therefore
came into being to scratch my itch of a similar library that not only has
less legacy baggage, but which can also be used with e.g. SpatialLite.

## Contributing

If you would like to contribute support for more functions (PostGIS and
SpatialLite both provide a frighteningly impressive amount of them!) or
support for other databases, do not hesitate to make a PR and the author
will review and merge in a timely fashion.
