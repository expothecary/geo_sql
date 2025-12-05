defmodule GeoSQL.Common do
  @moduledoc """
  Commonly supported, but non-standard, GIS SQL functions. These are
  found in multiple database implementations, though they may differ in minor
  syntactical details in each implementation.

  ## Implementation differences

  In cases where the generated SQL differs based on the database in use, those
  functions will take an optional `Ecto.Repo` argument. When provided, this allows
  the function to decide which implementation-specific ipmlementation to use.

  When no `Ecto.Repo` is provided, functions default to `PostGIS`-compatible syntax.

  ## Database support

  The features in the `GeoSQL.Common` modules are intended to contain functions
  available in all support SQL GIS extensions.

  Some backends may require special initialization or
  dependencies loaded for some of these functions to work. For example, SpatiaLite
  must be built with the GEO package for some of these functions to be available.

  Consult the documentation for the database GIS extension being used for such
  requirements.
  """

  defmacro __using__(_) do
    quote do
      require GeoSQL.Common
      require GeoSQL.Common.ThreeD
      require GeoSQL.Common.Topo
      alias GeoSQL.Common
    end
  end

  require Ecto.Query

  use GeoSQL.RepoUtils

  @spec add_measure(
          line :: GeoSQL.geometry_input(),
          measure_start :: number,
          measure_end :: number
        ) ::
          GeoSQL.fragment()
  @doc group: "Linear Referencing"
  defmacro add_measure(line, measure_start, measure_end) do
    quote do
      fragment(
        "ST_AddMeasure(?,?,?)",
        unquote(line),
        unquote(measure_start),
        unquote(measure_end)
      )
    end
  end

  @spec add_point(
          line :: GeoSQL.geometry_input(),
          point :: GeoSQL.geometry_input(),
          position :: integer
        ) ::
          GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro add_point(line, point, position \\ -1) do
    quote do
      fragment(
        "ST_AddPoint(?,?,?)",
        unquote(line),
        unquote(point),
        unquote(position)
      )
    end
  end

  @spec as_ewkb(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) :: GeoSQL.fragment()
  @doc group: "Well-Known Binary (WKB)"
  defmacro as_ewkb(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_AsEWKB(?)", unquote(geometry))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("unhex(AsEWKB(?))", unquote(geometry))
    end
  end

  @spec as_ewkt(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) :: GeoSQL.fragment()
  @doc group: "Well-Known Text (WKT)"
  defmacro as_ewkt(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_AsEWKT(?)", unquote(geometry))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("AsEWKT(?)", unquote(geometry))
    end
  end

  @spec as_geojson(geometry :: GeoSQL.geometry_input(), Ecto.Repo.t() | nil) ::
          GeoSQL.fragment()
  @doc group: "Data Formats"
  defmacro as_geojson(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_AsGeoJSON(?)", unquote(geometry))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("AsGeoJSON(?)", unquote(geometry))
    end
  end

  @spec as_gml(
          geometry :: GeoSQL.geometry_input(),
          gml_version :: 2 | 3,
          precision :: pos_integer,
          Ecto.Repo.t()
        ) ::
          GeoSQL.fragment()
  @doc group: "Data Formats"
  defmacro as_gml(geometry, gml_version, precision, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do
          fragment(
            "ST_AsGML(?,?,?)",
            unquote(gml_version),
            unquote(geometry),
            unquote(precision)
          )
        end

      Ecto.Adapters.SQLite3 ->
        quote do
          fragment("AsGML(?,?,?)", unquote(gml_version), unquote(geometry), unquote(precision))
        end
    end
  end

  @spec as_kml(
          geometry :: GeoSQL.geometry_input(),
          precision :: pos_integer,
          name :: String.t(),
          Ecto.Repo.t() | nil
        ) ::
          GeoSQL.fragment()
  @doc group: "Data Formats"
  defmacro as_kml(geometry, precision, name \\ "", repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do
          fragment("ST_AsKML(?,?,?)", unquote(geometry), unquote(precision), unquote(name))
        end

      Ecto.Adapters.SQLite3 ->
        quote do
          fragment("AsKML(?,'',?,?)", unquote(name), unquote(geometry), unquote(precision))
        end
    end
  end

  @doc group: "Measurement"
  defmacro azimuth(originGeometry, targetGeometry) do
    quote do: fragment("ST_Azimuth(?,?)", unquote(originGeometry), unquote(targetGeometry))
  end

  @spec bd_m_poly_from_text(
          String.t() | GeoSQL.geometry_input(),
          pos_integer | GeoSQL.geometry_input()
        ) ::
          GeoSQL.fragment()
  @doc group: "Well-Known Text (WKT)"
  defmacro bd_m_poly_from_text(wkt, srid) do
    quote do: fragment("ST_BdMPolyFromText(?, ?)", unquote(wkt), unquote(srid))
  end

  @spec bd_poly_from_text(
          String.t() | GeoSQL.geometry_input(),
          pos_integer | GeoSQL.geometry_input()
        ) ::
          GeoSQL.fragment()
  @doc group: "Well-Known Text (WKT)"
  defmacro bd_poly_from_text(wkt, srid) do
    quote do: fragment("ST_BdPolyFromText(?, ?)", unquote(wkt), unquote(srid))
  end

  @doc group: "Geometry Processing"
  defmacro build_area(geometry) do
    quote do: fragment("ST_BuildArea(?)", unquote(geometry))
  end

  @spec closest_point(
          GeoSQL.geometry_input(),
          GeoSQL.geometry_input(),
          use_spheroid? :: boolean,
          Ecto.Repo.t()
        ) ::
          GeoSQL.fragment()
  @doc group: "Measurement"
  defmacro closest_point(geometryA, geometryB, use_spheroid? \\ false, repo \\ nil) do
    if use_spheroid? and RepoUtils.adapter(repo) == Ecto.Adapters.Postgres do
      quote do: fragment("ST_ClosestPoint(?,?,true)", unquote(geometryA), unquote(geometryB))
    else
      quote do: fragment("ST_ClosestPoint(?,?)", unquote(geometryA), unquote(geometryB))
    end
  end

  @spec collection_extract(
          collection :: GeoSQL.geometry_input(),
          type :: :point | :line_string | :polygon
        ) :: GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro collection_extract(collection, type) do
    type_value =
      case type do
        :point -> 1
        :linestring -> 2
        :polygon -> 3
      end

    quote do: fragment("ST_CollectionExtract(?,?)", unquote(collection), unquote(type_value))
  end

  @spec concave_hull(GeoSQL.geometry_input(), precision :: number(), allow_holes? :: boolean) ::
          GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro concave_hull(geometry, precision \\ 1, allow_holes? \\ false) do
    quote do
      fragment(
        "ST_ConcaveHull(?,?,?)",
        unquote(geometry),
        unquote(precision),
        unquote(allow_holes?)
      )
    end
  end

  @doc group: "Coverages"
  defmacro covers(geometryA, geometryB) do
    quote do: fragment("ST_Covers(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Coverages"
  defmacro covered_by(geometryA, geometryB) do
    quote do: fragment("ST_CoveredBy(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Geometry Constructors"
  defmacro collect(geometryList) do
    quote do: fragment("ST_Collect(?)", unquote(geometryList))
  end

  @doc group: "Geometry Constructors"
  defmacro collect(geometryA, geometryB) do
    quote do: fragment("ST_Collect(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Math Utils"
  defmacro degrees(radians) do
    quote do: fragment("Degrees(?)", unquote(radians))
  end

  @spec estimated_extent(
          table :: String.t() | {schema :: String.t(), table :: String.t()},
          column :: String.t(),
          Ecto.Repo.t() | nil
        ) :: GeoSQL.fragment()
  @doc group: "Bounding Boxes"
  defmacro estimated_extent(table, column, repo \\ nil)

  defmacro estimated_extent({schema, table}, column, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do
          fragment(
            "ST_EstimatedExtent(?, ?, ?)::geometry",
            unquote(schema),
            unquote(table),
            unquote(column)
          )
        end

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GetLayerExtent(?, ?)", unquote(table), unquote(column))
    end
  end

  defmacro estimated_extent(table, column, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_EstimatedExtent(?, ?)::geometry", unquote(table), unquote(column))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GetLayerExtent(?, ?)", unquote(table), unquote(column))
    end
  end

  @spec expand(
          geometry :: GeoSQL.geometry_input(),
          units_to_expand :: GeoSQL.fragment() | number
        ) :: GeoSQL.fragment()
  @doc group: "Bounding Boxes"
  defmacro expand(geometry, units_to_expand) do
    quote do: fragment("ST_Expand(?,?)", unquote(geometry), unquote(units_to_expand))
  end

  @spec extent(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) :: GeoSQL.fragment()
  @doc group: "Bounding Boxes"
  defmacro extent(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_Extent(?)::geometry", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("extent(?)", unquote(geometry))
    end
  end

  @spec extent(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro exterior_ring(geometry) do
    quote do: fragment("ST_ExteriorRing(?)::geometry", unquote(geometry))
  end

  @spec flip_coordinates(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) :: GeoSQL.fragment()
  @doc group: "Geometry Mutations"
  defmacro flip_coordinates(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_FlipCoordinates(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("SwapCoordinates(?)", unquote(geometry))
    end
  end

  @spec geom_from_ewkb(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) :: GeoSQL.fragment()
  @doc group: "Well-Known Binary (WKB)"
  defmacro geom_from_ewkb(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_GeomFromEWKB(?)", unquote(geometry))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GeomFromEWKB(?)", unquote(geometry))
    end
  end

  @spec geom_from_ewkt(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) :: GeoSQL.fragment()
  @doc group: "Well-Known Text (WKT)"
  defmacro geom_from_ewkt(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_GeomFromEWKT(?)", unquote(geometry))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GeomFromEWKT(?)", unquote(geometry))
    end
  end

  @spec geom_from_geojson(geojson :: GeoSQL.geometry_input() | String.t(), Ecto.Repo.t() | nil) ::
          GeoSQL.fragment()
  @doc group: "Data Formats"
  defmacro geom_from_geojson(geojson, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_GeomFromGeoJSON(?)", unquote(geojson))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GeomFromGeoJSON(?)", unquote(geojson))
    end
  end

  @spec geom_from_gml(
          gml :: GeoSQL.geometry_input() | String.t(),
          srid :: non_neg_integer,
          Ecto.Repo.t() | nil
        ) ::
          GeoSQL.fragment()
  @doc group: "Data Formats"
  @doc "Passing an srid of 0 (the default) will not set an srid on the results. It is ignored for Spatialite in all cases."
  defmacro geom_from_gml(gml, srid \\ 0, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        if srid > 0 do
          quote do: fragment("ST_GeomFromGML(?,?)", unquote(gml), unquote(srid))
        else
          quote do: fragment("ST_GeomFromGML(?)", unquote(gml))
        end

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GeomFromGML(?)", unquote(gml))
    end
  end

  @spec geom_from_kml(kml :: GeoSQL.geometry_input() | String.t(), Ecto.Repo.t() | nil) ::
          GeoSQL.fragment()
  @doc group: "Data Formats"
  defmacro geom_from_kml(kml, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_GeomFromKML(?)", unquote(kml))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GeomFromKML(?)", unquote(kml))
    end
  end

  @spec interpolate_point(
          line :: GeoSQL.geometry_input(),
          point :: GeoSQL.geometry_input()
        ) ::
          GeoSQL.fragment()
  @doc group: "Linear Referencing"
  defmacro interpolate_point(line, point) do
    quote do: fragment("ST_InterpolatePoint(?,?)", unquote(line), unquote(point))
  end

  @spec is_polygon_clockwise(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro is_polygon_clockwise(geometry) do
    quote do: fragment("ST_IsPolygonCW(?)", unquote(geometry))
  end

  @spec is_polygon_counter_clockwise(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro is_polygon_counter_clockwise(geometry) do
    quote do: fragment("ST_IsPolygonCCW(?)", unquote(geometry))
  end

  @spec is_valid_detail(geometry :: GeoSQL.geometry_input(), esri_compat? :: boolean) ::
          GeoSQL.fragment()
  @doc group: "Geometry Validation"
  defmacro is_valid_detail(geometry, esri_compat? \\ false) do
    flags = if esri_compat?, do: 1, else: 0
    quote do: fragment("ST_IsValidDetail(?,?)", unquote(geometry), unquote(flags))
  end

  @spec is_valid_reason(geometry :: GeoSQL.geometry_input(), esri_compat? :: boolean) ::
          GeoSQL.fragment()
  @doc group: "Geometry Validation"
  defmacro is_valid_reason(geometry, esri_compat? \\ false) do
    flags = if esri_compat?, do: 1, else: 0
    quote do: fragment("ST_IsValidReason(?,?)", unquote(geometry), unquote(flags))
  end

  @spec largest_empty_circle(GeoSQL.geometry_input(), tolerance :: number(), Ecto.Repo.t() | nil) ::
          GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro largest_empty_circle(geometry, tolerance \\ 0.0, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_LargestEmptyCircle(?,?)", unquote(geometry), unquote(tolerance))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GEOSLargestEmptyCircle(?,?)", unquote(geometry), unquote(tolerance))
    end
  end

  @spec line_interpolate_point(
          line :: GeoSQL.geometry_input(),
          fraction :: number,
          use_spheroid? :: boolean,
          Ecto.Repo.t() | nil
        ) ::
          GeoSQL.fragment()
  @doc group: "Linear Referencing"
  @doc """
  Spatialite does not support spheroid calculations, and therefore `use_spheroid?` is ignored
  on that platform.
  """
  defmacro line_interpolate_point(line, fraction, use_spheroid? \\ false, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do
          fragment(
            "ST_LineInterpolatePoint(?,?,?)",
            unquote(line),
            unquote(fraction),
            unquote(use_spheroid?)
          )
        end

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("ST_Line_Interpolate_Point(?,?)", unquote(line), unquote(fraction))
    end
  end

  @spec line_interpolate_points(
          line :: GeoSQL.geometry_input(),
          fraction :: number,
          use_spheroid? :: boolean,
          Ecto.Repo.t() | nil
        ) ::
          GeoSQL.fragment()
  @doc group: "Linear Referencing"
  @doc "Note that Spatialite does not support spheroid calculations."
  defmacro line_interpolate_points(line, fraction, use_spheroid? \\ true, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do
          fragment(
            "ST_LineInterpolatePoints(?,?,?,true)",
            unquote(line),
            unquote(fraction),
            unquote(use_spheroid?)
          )
        end

      Ecto.Adapters.SQLite3 ->
        quote do
          fragment(
            "ST_Line_Interpolate_Equidistant_Points(?,?)",
            unquote(line),
            unquote(fraction)
          )
        end
    end
  end

  @spec line_locate_point(
          line :: GeoSQL.geometry_input(),
          point :: GeoSQL.geometry_input(),
          use_spheroid? :: boolean,
          Ecto.Repo.t() | nil
        ) ::
          GeoSQL.fragment()
  @doc group: "Linear Referencing"
  @doc """
  Spatialite does not support spheroid calculations, and therefore `use_spheroid?` is ignored
  on that platform.
  """
  defmacro line_locate_point(line, point, use_spheroid? \\ false, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do
          fragment(
            "ST_LineLocatePoint(?,?,?)",
            unquote(line),
            unquote(point),
            unquote(use_spheroid?)
          )
        end

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("ST_Line_Locate_Point(?,?)", unquote(line), unquote(point))
    end
  end

  @spec line_substring(
          line :: GeoSQL.geometry_input() | GeoSQL.fragment(),
          start_fraction :: number,
          end_fraction :: number,
          Ecto.Repo.t() | nil
        ) ::
          GeoSQL.fragment()
  @doc group: "Linear Referencing"
  defmacro line_substring(line, start_fraction, end_fraction, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do
          fragment(
            "ST_LineSubstring(?,?,?)",
            unquote(line),
            unquote(start_fraction),
            unquote(end_fraction)
          )
        end

      Ecto.Adapters.SQLite3 ->
        quote do
          fragment(
            "ST_Line_Substring(?,?,?)",
            unquote(line),
            unquote(start_fraction),
            unquote(end_fraction)
          )
        end
    end
  end

  @spec line_merge(GeoSQL.geometry_input(), directed? :: boolean, Ecto.Repo.t() | nil) ::
          GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro line_merge(geometry, directed? \\ false, repo \\ nil) do
    if directed? and RepoUtils.adapter(repo) == Ecto.Adapters.Postgres do
      quote do: fragment("ST_LineMerge(?,true)", unquote(geometry))
    else
      quote do: fragment("ST_LineMerge(?)", unquote(geometry))
    end
  end

  @spec locate_along(GeoSQL.geometry_input(), measure :: number) :: GeoSQL.fragment()
  @doc group: "Linear Referencing"
  defmacro locate_along(geometry, measure) when is_number(measure) do
    quote do: fragment("ST_LocateAlong(?,?)", unquote(geometry), unquote(measure))
  end

  @spec locate_between(GeoSQL.geometry_input(), measure_start :: number, measure_end :: number) ::
          GeoSQL.fragment()
  @doc group: "Linear Referencing"
  defmacro locate_between(geometry, measure_start, measure_end)
           when is_number(measure_start) and is_number(measure_end) do
    quote do
      fragment(
        "ST_LocateBetween(?,?,?)",
        unquote(geometry),
        unquote(measure_start),
        unquote(measure_end)
      )
    end
  end

  @spec make_point(
          x :: [GeoSQL.fragment()] | [number],
          y :: [GeoSQL.fragment()] | [number],
          Ecto.Repo.t() | nil
        ) :: GeoSQL.fragment()
  @doc group: "Geometry Constructors"
  defmacro make_point(x, y, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MakePoint(?,?)", unquote(x), unquote(y))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("MakePoint(?,?)", unquote(x), unquote(y))
    end
  end

  @spec make_point_z(
          x :: [GeoSQL.fragment()] | [number],
          y :: [GeoSQL.fragment()] | [number],
          z :: [GeoSQL.fragment()] | [number],
          Ecto.Repo.t() | nil
        ) :: GeoSQL.fragment()
  @doc group: "Geometry Constructors"
  defmacro make_point_z(x, y, z, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MakePoint(?,?,?)", unquote(x), unquote(y), unquote(z))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("MakePointZ(?,?,?)", unquote(x), unquote(y), unquote(z))
    end
  end

  @spec make_point_zm(
          x :: [GeoSQL.fragment()] | [number],
          y :: [GeoSQL.fragment()] | [number],
          z :: [GeoSQL.fragment()] | [number],
          m :: [GeoSQL.fragment()] | [number],
          Ecto.Repo.t() | nil
        ) :: GeoSQL.fragment()
  @doc group: "Geometry Constructors"
  defmacro make_point_zm(x, y, z, m, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do
          fragment("ST_MakePoint(?,?,?,?)", unquote(x), unquote(y), unquote(z), unquote(m))
        end

      Ecto.Adapters.SQLite3 ->
        quote do
          fragment("MakePointZM(?,?,?,?)", unquote(x), unquote(y), unquote(z), unquote(m))
        end
    end
  end

  @spec make_point_m(
          x :: [GeoSQL.fragment()] | [number],
          y :: [GeoSQL.fragment()] | [number],
          z :: [GeoSQL.fragment()] | [number],
          Ecto.Repo.t() | nil
        ) :: GeoSQL.fragment()
  @doc group: "Geometry Constructors"
  defmacro make_point_m(x, y, z, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MakePointM(?,?,?)", unquote(x), unquote(y), unquote(z))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("MakePointM(?,?,?)", unquote(x), unquote(y), unquote(z))
    end
  end

  @doc group: "Geometry Validation"
  defmacro make_valid(geometry) do
    quote do: fragment("ST_MakeValid(?)", unquote(geometry))
  end

  @spec max_coord(GeoSQL.geometry_input(), axis :: :x | :y | :z, Ecto.Repo.t() | nil) ::
          GeoSQL.fragment()
  @doc group: "Bounding Boxes"
  defmacro max_coord(geometry, axis, repo \\ nil)

  defmacro max_coord(geometry, :x, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_XMax(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("ST_MaxX(?)", unquote(geometry))
    end
  end

  defmacro max_coord(geometry, :y, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_YMax(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("ST_MaxY(?)", unquote(geometry))
    end
  end

  defmacro max_coord(geometry, :z, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_ZMax(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("ST_MaxZ(?)", unquote(geometry))
    end
  end

  @doc group: "Measurement"
  defmacro max_distance(geometryA, geometryB) do
    quote do: fragment("ST_MaxDistance(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec maximum_inscribed_circle(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) ::
          GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro maximum_inscribed_circle(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MaximumInscribedCircle(?)", unquote(geometry))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GEOSMaximumInscribedCircle(?)", unquote(geometry))
    end
  end

  @spec min_coord(GeoSQL.geometry_input(), axis :: :x | :y | :z, Ecto.Repo.t() | nil) ::
          GeoSQL.fragment()
  @doc group: "Bounding Boxes"
  defmacro min_coord(geometry, axis, repo \\ nil)

  defmacro min_coord(geometry, :x, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_XMin(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("ST_MinX(?)", unquote(geometry))
    end
  end

  defmacro min_coord(geometry, :y, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_YMin(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("ST_MinY(?)", unquote(geometry))
    end
  end

  defmacro min_coord(geometry, :z, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_ZMin(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("ST_MinZ(?)", unquote(geometry))
    end
  end

  @spec minimum_bounding_circle(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) :: GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro minimum_bounding_circle(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MinimumBoundingCircle(?)", unquote(geometry))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GEOSMinimumBoundingCircle(?)", unquote(geometry))
    end
  end

  @spec minimum_bounding_radius(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) :: GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro minimum_bounding_radius(geometry, repo \\ nil) do
    quote do: fragment("ST_MinimumBoundingRadius(?)", unquote(geometry))
  end

  @doc group: "Measurement"
  defmacro minimum_clearance(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_MinimumClearance(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("GEOSMinimumClearance(?)", unquote(geometry))
    end
  end

  @doc group: "Measurement"
  defmacro minimum_clearance_line(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MinimumClearanceLine(?)", unquote(geometry))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GEOSMinimumClearanceLine(?)", unquote(geometry))
    end
  end

  @spec multi(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro multi(collection) do
    quote do: fragment("ST_Multi(?)", unquote(collection))
  end

  @doc group: "Overlays"
  defmacro node(geometry) do
    quote do: fragment("ST_Node(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro number_of_dimensions(geometry) do
    quote do: fragment("ST_NDims(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro number_of_points(geometry) do
    quote do: fragment("ST_NPoints(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro number_of_rings(geometry) do
    quote do: fragment("ST_NRings(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro number_of_geometries(geometry_collection) do
    quote do: fragment("ST_NumGeometeries(?)", unquote(geometry_collection))
  end

  @doc group: "Geometry Processing"
  defmacro oriented_envelope(geometry) do
    quote do: fragment("ST_OrientedEnvelope(?)", unquote(geometry))
  end

  @doc group: "Geometry Processing"
  defmacro offset_curve(line, distance) when is_number(distance) do
    quote do: fragment("ST_OffsetCurve(?,?)", unquote(line), unquote(distance))
  end

  @doc group: "Geometry Processing"
  defmacro polygonize(geometry) do
    quote do: fragment("ST_Polygonize(?)", unquote(geometry))
  end

  @spec project(geometry :: GeoSQL.geometry_input(), distance :: number, azimuth :: number) ::
          GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro project(geometry, distance, azimuth) do
    quote do
      fragment(
        "ST_Project(?, ?, ?)",
        unquote(geometry),
        unquote(distance),
        unquote(azimuth)
      )
    end
  end

  @doc group: "Math Utils"
  defmacro radians(degrees) do
    quote do: fragment("Radians(?)", unquote(degrees))
  end

  @doc group: "Geometry Processing"
  defmacro reduce_precision(geometry, grid_size) when is_number(grid_size) do
    quote do: fragment("ST_ReducePrecision(?, ?)", unquote(geometry), unquote(grid_size))
  end

  @spec remove_point(line :: GeoSQL.geometry_input(), offset :: integer) ::
          GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro remove_point(line, offset) do
    quote do
      fragment(
        "ST_RemovePoint(?, ?, ?)",
        unquote(line),
        unquote(offset)
      )
    end
  end

  @spec remove_repeated_points(
          GeoSQL.geometry_input(),
          tolerance :: number,
          Ecto.Repo.t() | nil
        ) ::
          GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro remove_repeated_points(geometry, tolerance \\ 0, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_RemoveRepeatedPoints(?,?)", unquote(geometry), unquote(tolerance))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("RemoveRepeatedPoints(?,?)", unquote(geometry), unquote(tolerance))
    end
  end

  @doc group: "Topology Relationships"
  defmacro relate_match(matrix, pattern) when is_binary(matrix) and is_binary(pattern) do
    quote do: fragment("ST_Relatematch(?, ?)", unquote(matrix), unquote(pattern))
  end

  @spec reverse(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro reverse(geometry) do
    quote do: fragment("ST_Reverse(?)", unquote(geometry))
  end

  @doc group: "Affine Transformations"
  defmacro rotate(geometry, rotate_radians, repo \\ nil) when is_number(rotate_radians) do
    if RepoUtils.adapter(repo) == Ecto.Adapters.SQLite3 do
      degrees_per_radian = 57.2958
      degrees = rotate_radians * degrees_per_radian
      quote do: fragment("RotateCoordinates(?, ?)", unquote(geometry), unquote(degrees))
    else
      quote do: fragment("ST_Rotate(?, ?)", unquote(geometry), unquote(rotate_radians))
    end
  end

  @spec segmentize(geometry :: GeoSQL.geometry_input(), max_segement_length :: number) ::
          GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro segmentize(geometry, max_segement_length) do
    quote do: fragment("ST_Segmentize(?, ?)", unquote(geometry), unquote(max_segement_length))
  end

  @spec scale(GeoSQL.geometry_input(), scale_x :: number, scale_y :: number, Ecto.Repo.t() | nil) ::
          GeoSQL.fragment()
  @doc group: "Affine Transformations"
  defmacro scale(geometry, scale_x, scale_y, repo \\ nil)
           when is_number(scale_x) and is_number(scale_y) do
    if RepoUtils.adapter(repo) == Ecto.Adapters.SQLite3 do
      quote do
        fragment(
          "ScaleCoordinates(?,?,?)",
          unquote(geometry),
          unquote(scale_x),
          unquote(scale_y)
        )
      end
    else
      quote do: fragment("ST_Scale(?,?,?)", unquote(geometry), unquote(scale_x), unquote(scale_y))
    end
  end

  @spec set_point(
          geometry :: GeoSQL.geometry_input(),
          index :: integer,
          point :: GeoSQL.geometry_input()
        ) ::
          GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro set_point(geometry, index, point) do
    quote do: fragment("ST_SetPoint(?, ?, ?)", unquote(geometry), unquote(index), unquote(point))
  end

  @spec set_srid(
          geometry :: GeoSQL.geometry_input(),
          srid :: pos_integer,
          Ecto.Repo.t() | nil
        ) ::
          GeoSQL.fragment()
  @doc group: "Spatial Reference Systems"
  defmacro set_srid(geometry, srid, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_SetSRID(?, ?)", unquote(geometry), unquote(srid))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("SetSRID(?, ?)", unquote(geometry), unquote(srid))
    end
  end

  @doc group: "Geometry Processing"
  defmacro shared_paths(geometryA, geometryB) do
    quote do: fragment("ST_SharedPaths(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  @spec shift_longitude(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) :: GeoSQL.fragment()
  @doc group: "Geometry Mutations"
  defmacro shift_longitude(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_ShiftLongitude(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("ST_Shift_Longitude(?)", unquote(geometry))
    end
  end

  @spec shortest_line(
          GeoSQL.geometry_input(),
          GeoSQL.geometry_input(),
          use_spheroid? :: boolean,
          Ecto.Repo.t() | nil
        ) ::
          GeoSQL.fragment()
  @doc group: "Measurement"
  defmacro shortest_line(geometryA, geometryB, use_spheroid? \\ false, repo \\ nil) do
    if use_spheroid? and RepoUtils.adapter(repo) == Ecto.Adapters.Postgres do
      quote do: fragment("ST_ShortestLine(?,?,true)", unquote(geometryA), unquote(geometryB))
    else
      quote do: fragment("ST_ShortestLine(?,?)", unquote(geometryA), unquote(geometryB))
    end
  end

  @doc group: "Geometry Processing"
  defmacro simplify(geometry, tolerance) when is_number(tolerance) do
    quote do: fragment("ST_Simplify(?, ?)", unquote(geometry), unquote(tolerance))
  end

  @doc group: "Geometry Processing"
  defmacro simplify_preserve_topology(geometry, tolerance) when is_number(tolerance) do
    quote do: fragment("ST_SimplifyPreserveTopology(?, ?)", unquote(geometry), unquote(tolerance))
  end

  @spec snap_to_grid(
          GeoSQL.geometry_input(),
          reference :: GeoSQL.geometry_input(),
          precision :: number
        ) :: GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro snap(geometry, reference, precision) do
    quote do
      fragment(
        "ST_SnapToGrid(?,?)",
        unquote(geometry),
        unquote(reference),
        unquote(precision)
      )
    end
  end

  @spec snap_to_grid(GeoSQL.geometry_input(), size :: number) :: GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro snap_to_grid(geometry, size) do
    quote do: fragment("ST_SnapToGrid(?,?)", unquote(geometry), unquote(size))
  end

  @spec snap_to_grid(GeoSQL.geometry_input(), size_x :: number, size_y :: number) ::
          GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro snap_to_grid(geometry, size_x, size_y) do
    quote do
      fragment(
        "ST_SnapToGrid(?,?,?)",
        unquote(geometry),
        unquote(size_x),
        unquote(size_y)
      )
    end
  end

  @spec snap_to_grid(
          GeoSQL.geometry_input(),
          origin_x :: number,
          origin_y :: number,
          size_x :: number,
          size_y :: number
        ) :: GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro snap_to_grid(geometry, origin_x, origin_y, size_x, size_y) do
    quote do
      fragment(
        "ST_SnapToGrid(?,?,?,?,?)",
        unquote(geometry),
        unquote(origin_x),
        unquote(origin_y),
        unquote(size_x),
        unquote(size_y)
      )
    end
  end

  @spec snap_to_grid(
          GeoSQL.geometry_input(),
          point :: GeoSQL.geometry_input(),
          size_x :: number,
          size_y :: number,
          size_z :: number,
          size_m :: number
        ) :: GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro snap_to_grid(geometry, point, size_x, size_y, size_z, size_m) do
    quote do
      fragment(
        "ST_SnapToGrid(?,?,?,?,?,?)",
        unquote(geometry),
        unquote(point),
        unquote(size_x),
        unquote(size_y),
        unquote(size_z),
        unquote(size_m)
      )
    end
  end

  @doc group: "Overlays"
  defmacro split(inputGeometry, bladeGeometry) do
    quote do: fragment("ST_Split(?, ?)", unquote(inputGeometry), unquote(bladeGeometry))
  end

  @doc group: "Overlays"
  defmacro subdivide(geometry, max_vertices \\ 256) do
    quote do: fragment("ST_Subdivide(?, ?)", unquote(geometry), unquote(max_vertices))
  end

  @doc group: "Affine Transformations"
  defmacro translate(geometry, delta_x, delta_y, delta_z \\ 0) do
    quote do
      fragment(
        "ST_Translate(?,?,?,?)",
        unquote(geometry),
        unquote(delta_x),
        unquote(delta_y),
        unquote(delta_z)
      )
    end
  end

  @spec transform_pipeline(
          GeoSQL.geometry_input(),
          pipeline :: String.t(),
          srid :: pos_integer,
          Ecto.Repo.t() | nil
        ) :: GeoSQL.fragment()
  @doc group: "Spatial Reference Systems"
  defmacro transform_pipeline(geometry, pipeline, srid, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do
          fragment(
            "ST_TransformPipeline(?,?,?)",
            unquote(geometry),
            unquote(pipeline),
            unquote(srid)
          )
        end

      Ecto.Adapters.SQLite3 ->
        quote do
          fragment(
            "ST_Transform(?,?,NULL,?)",
            unquote(geometry),
            unquote(srid),
            unquote(pipeline)
          )
        end
    end
  end

  @spec triangulate_polygon(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) :: GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro triangulate_polygon(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_TriangulatePolygon(?)", unquote(geometry))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("ConstrainedDelaunayTriangulation(?)", unquote(geometry))
    end
  end

  @doc group: "Overlays"
  defmacro unary_union(geometry) do
    quote do: fragment("ST_UnaryUnion(?, ?)", unquote(geometry))
  end
end
