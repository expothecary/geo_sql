# Changelog

This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## [1.7.0] xx-01-2026
* Dependencies
  * Bumped minimum Elixir dependency to 1.18 to be able to use the JSON module, as the `geometry` library is not fully compatible with `:json`
* Improvements
  * MySQL/MariaDB databases are now supported if the `myxql` library is available as a
    dependency.
  * The PostGIS and SpatiaLite extensions now support using structs from the `geo`
    library in mutations. This allows compatibility with libraries and Ecto schemas 
    using `%Geo.*{}` structs. All queries still return `%Geometry.*{}` structs.

## [1.6.0] 21-12-2025

* Improvements
  * Added `PostGIS.crossing_direction` which translates the arcane integer return values PostGIS uses for crossing directions to a developer-friendly atom (e.g. `:left`)
  * Added `PostGIS.dimensionality` which translates the arcane integer return values PostGIS uses for dimension flags to a developer-friendly atom (e.g. `:dim_3m`)
  * Added support for encoding and decoding the Box2D PostGIS type via the %GeoSQL.PostGIS.Box2D{} struct
  * Parameters are now optional on `PostGIS.make_valid`
  * `PostGIS.scale` accepts Ecto fragments as parameters (not only literal numbers)
  * Test coverage of GeoSQL.PostGIS functions is complete
* Fixes
  * Correct the number of parameters passed to PostGIS in `PostGIS.swap_ordinates`

## [1.5.1] 21-12-2025

* Improvements
  * Test coverage of GeoSQL.Common functions is complete
* Fixes
  * Fix `GeoSQL.Common.unary_union`
  * Fix `GeoSQL.Common.remove_point`
  * Fix a possible math exception in `GeoSQL.Common.rotate`
  * Allow fragments to be used for any parameter in the `GeoSQL.Common` macros

## [1.5.0] 20-12-2025

* Improvements
  * Expanded unit test coverage
* Fixes
  * `Common.line_interpolate_points` supports the `repeat?` parameter
  * Fix `Common.maximum_inscribed_circle` with SpatiaLite

## [1.4.2] 05-12-2025

* Improvements
  * Expanded unit test coverage
  * SpatiaLit support expanded to include the following functions:
    * `MM.gml_to_sql`
    * `MM.num_patches`
    * `MM.patch_n`
* Fixes
  * `Common.min_coord(geometry, :x, repo)` works correctly now (`:y` and `:z` variants were unaffected)
  * SpatiaLite documentation for the function behind `minimum_bounding_radius` was wrong; adapted to the real names used in the SaptiaLite library rather than what their docs say
  * Fix typo in `Common.number_of_geometries`

## [1.4.1] 05-12-2025

* Improvements
  * Expanded unit test coverage
  * More documentation
  * Style fixes suggested by `credo`
* Fixes
  * `GeoSQL.PostGIS.expand` can be called with more than two dimensions
  * `GeoSQL.Common.ST_EstimatedExtent` supports `{schema, table}` and just `table_name`

## [1.4.0] 01-12-2025

* Improvements
  * Degree<->radians conversion utilities in `Common.degrees/1` and `Common.radians/1`
  * Expanded unit test coverage
* Fixes
  * Affine transformations with z-values with PostGIS.affine/11 had wrong number of placeholders

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
