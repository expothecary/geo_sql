# Changelog

This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [1.3.0] 21-07-2025

* Improvements
  * Introduce the `GeoSQL.Geometry.Geopackage` Ecto type, allowing Ecto schemas to
    have geometry fields backed by Geopackage data. Currently only supported with
    SQLite3 databases, and relies on the Spatialite module being available.

## [1.2.0] 20-07-2025

* Improvements
  * Support for SpatiaLite's Geopackage interoperability functions:
    * `GeoSQL.SpatiaLite.as_gpb`: convert a geometry to a Geopackage binary
    * `GeoSQL.SpatiaLite.geom_from_gpb`: convert a Geopackage binary to a geometry
    * `GeoSQL.SpatiaLite.is_valid_gpb`: checks validity of a Geopackage blob
  * More tests
* Fixes
  * Standardized on the proper spelling of SpatiaLite

## [1.1.0] 09-07-2025

* Improvements
  * `QueryUtils.decode_geometry` now supports tuples in addition to maps and lists.
  * Expanded unit test coverage.
* Fixes
  * `MM.perimeter` had misleading parameter names.

## [1.0.0] 09-07-2025

* Breaking changes
  * All SQL/MM functions were collapsed into a single MM module.
    Migration: Replace all instances of `MM2` and `MM3` with `MM`.
* Improvements
  * Expanded unit test suite considerably, improved vector tile generation tests
* Fixes
  * `MM.locate_along` was missing a parameter placeholder

## [0.1.0] 02-07-2025

First release.

* Spatial database support
  * PostGIS
  * Spatialite
* GIS SQL functions (290+)
  * SQL/MM functions (part 2 and 3)
  * Common, but non-standard functions
  * Non-stanadard PostGIS functions
  * Mapbox vector tile generation (PostGIS only)
* Eco Schema types
  * GeoSQL.Geometry - supports any geometry
  * GeoSQL.Geography - suports any geography
  * GeoSQL.Geometry.<Type> - specific Geometry types (points, lines, polygons, etc.)
  * GeoSQL.Int4
