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
  dependencies loaded for some of these functions to work. For examplke, SpatialLite
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

  require GeoSQL.RepoUtils
  alias GeoSQL.RepoUtils

  defguard is_fraction(value) when is_number(value) and value >= 0 and value <= 1

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

  @doc group: "Measurement"
  defmacro azimuth(originGeometry, targetGeometry) do
    quote do: fragment("ST_Azimuth(?,?)", unquote(originGeometry), unquote(targetGeometry))
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

  @spec concave_hull(GeoSQL.geometry_input(), precision :: number(), allow_holes? :: boolean) ::
          GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro concave_hull(geometry, precision \\ 1, allow_holes? \\ false)
           when is_fraction(precision) do
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

  @doc group: "Well-Known Text (WKT)"
  defmacro bd_poly_from_text(wkt, srid) do
    quote do: fragment("ST_BdPolyFromText(?, ?)", unquote(wkt), unquote(srid))
  end

  @doc group: "Well-Known Text (WKT)"
  defmacro bd_m_poly_from_text(wkt, srid) do
    quote do: fragment("ST_BdMPolyFromText(?, ?)", unquote(wkt), unquote(srid))
  end

  @doc group: "Geometry Processing"
  defmacro build_area(geometry) do
    quote do: fragment("ST_BuildArea(?)", unquote(geometry))
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
            "ST_ExtimatedEtent(?, ?, ?)::geometry",
            unquote(table),
            unquote(column),
            unquote(schema)
          )
        end

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GetLayerExtent(?, ?)", unquote(table), unquote(column))
    end
  end

  defmacro estimated_extent(table, column, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_ExtimatedEtent(?, ?)::geometry", unquote(table), unquote(column))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GetLayerExtent(?, ?)", unquote(table), unquote(column))
    end
  end

  @spec expand(
          geometry :: GeoSQL.geometry_input(),
          units_to_expand :: number
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

  @spec flip_coordinates(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) :: GeoSQL.fragment()
  @doc group: "Geometry Mutations"
  defmacro flip_coordinates(geometry, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_FlipCoordinate(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("ST_SwapCoordinates(?)", unquote(geometry))
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

  @spec largest_empty_circle(GeoSQL.geometry_input(), tolerance :: number(), Ecto.Repo.t() | nil) ::
          GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro largest_empty_circle(geometry, tolerance \\ 0.0, repo \\ nil)
           when is_fraction(tolerance) do
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
          Ecto.Repo.t() | nil
        ) ::
          GeoSQL.fragment()
  @doc group: "Linear Referencing"
  defmacro line_interpolate_point(line, fraction, repo) when is_fraction(fraction) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_LineInterpolatePoint(?,?)", unquote(line), unquote(fraction))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("ST_Line_Interpolate_Point(?,?)", unquote(line), unquote(fraction))
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
  defmacro line_interpolate_point(line, fraction, use_spheroid?, repo)
           when is_fraction(fraction) do
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
          Ecto.Repo.t() | nil
        ) ::
          GeoSQL.fragment()
  @doc group: "Linear Referencing"
  defmacro line_interpolate_points(line, fraction, repo) when is_fraction(fraction) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_LineInterpolatePoints(?,?,true)", unquote(line), unquote(fraction))

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

  @spec line_interpolate_points(
          line :: GeoSQL.geometry_input(),
          fraction :: number,
          use_spheroid? :: boolean,
          Ecto.Repo.t() | nil
        ) ::
          GeoSQL.fragment()
  @doc group: "Linear Referencing"
  defmacro line_interpolate_points(line, fraction, use_spheroid?, repo)
           when is_fraction(fraction) do
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
          Ecto.Repo.t() | nil
        ) ::
          GeoSQL.fragment()
  @doc group: "Linear Referencing"
  defmacro line_locate_point(line, point, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_LineLocatePoint(?,?)", unquote(line), unquote(point))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("ST_Line_Locate_Point(?,?)", unquote(line), unquote(point))
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
  defmacro line_locate_point(line, point, use_spheroid?, repo) do
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
  defmacro line_substring(line, start_fraction, end_fraction, repo)
           when is_fraction(start_fraction) and is_fraction(end_fraction) do
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
  defmacro line_merge(geometryA, directed? \\ false, repo \\ nil) do
    if directed? and RepoUtils.adapter(repo) == Ecto.Adapters.Postgres do
      quote do: fragment("ST_LineMerge(?,?,true)", unquote(geometryA))
    else
      quote do: fragment("ST_LineMerge(?,?)", unquote(geometryA))
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

  @doc group: "Geometry Validation"
  defmacro make_valid(geometry) do
    quote do: fragment("ST_MakeValid(?)", unquote(geometry))
  end

  @doc group: "Geometry Constructors"
  defmacro make_point(x, y, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MakePoint(?, ?)", unquote(x), unquote(y))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("MakePoint(?, ?)", unquote(x), unquote(y))
    end
  end

  @doc group: "Geometry Constructors"
  defmacro make_point(x, y, z, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MakePoint(?, ?, ?)", unquote(x), unquote(y), unquote(z))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("MakePoint(?, ?, ?)", unquote(x), unquote(y), unquote(z))
    end
  end

  @doc group: "Geometry Constructors"
  defmacro make_point(x, y, z, m, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do
          quote(
            do:
              fragment(
                "ST_MakePoint(?, ?, ?, ?)",
                unquote(x),
                unquote(y),
                unquote(z),
                unquote(m)
              )
          )
        end

      Ecto.Adapters.SQLite3 ->
        quote do
          fragment(
            "MakePointZM(?, ?, ?, ?)",
            unquote(x),
            unquote(y),
            unquote(z),
            unquote(m)
          )
        end
    end
  end

  @spec min_coord(GeoSQL.geometry_input(), axis :: :x | :y | :z, Ecto.Repo.t() | nil) ::
          GeoSQL.fragment()
  @doc group: "Bounding Boxes"
  defmacro min_coord(geometry, :x, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_MinX(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("ST_XMin(?)", unquote(geometry))
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

  @spec max_coord(GeoSQL.geometry_input(), axis :: :x | :y | :z, Ecto.Repo.t() | nil) ::
          GeoSQL.fragment()
  @doc group: "Bounding Boxes"
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
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MinimumBoundingRadius(?)", unquote(geometry))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GEOSMinimumBoundingRadius(?)", unquote(geometry))
    end
  end

  @doc group: "Measurement"
  defmacro minimum_clearance(geometry, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_MinimumClearance(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("GEOSMinimumClearance(?)", unquote(geometry))
    end
  end

  @doc group: "Measurement"
  defmacro minimum_clearance_line(geometry, repo) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MinimumClearanceLine(?)", unquote(geometry))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GEOSMinimumClearanceLine(?)", unquote(geometry))
    end
  end

  @doc group: "Overlays"
  defmacro node(geometry) do
    quote do: fragment("ST_Node(?)", unquote(geometry))
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

  @doc group: "Topology Relationships"
  defmacro relate_match(matrix, pattern) when is_binary(matrix) and is_binary(pattern) do
    quote do: fragment("ST_Relatematch(?, ?)", unquote(matrix), unquote(pattern))
  end

  @doc group: "Geometry Processing"
  defmacro reduce_precision(geometry, grid_size) when is_number(grid_size) do
    quote do: fragment("ST_ReducePrecision(?, ?)", unquote(geometry), unquote(grid_size))
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

  @doc group: "Geometry Processing"
  defmacro shared_paths(geometryA, geometryB) do
    quote do: fragment("ST_SharedPaths(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Geometry Mutations"
  @spec shift_longitude(GeoSQL.geometry_input(), Ecto.Repo.t()) :: GeoSQL.fragment()
  defmacro shift_longitude(geometry, repo) do
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

  @spec triangulate_polygon(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) :: GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro triangulate_polygon(geometry, repo \\ nil) do
    if RepoUtils.adapter(repo) == Ecto.Adapters.SQLite3 do
      quote do: fragment("ConstrainedDelaunayTriangulation(?)", unquote(geometry))
    else
      quote do: fragment("ST_TriangulatePolygon()", unquote(geometry))
    end
  end

  @doc group: "Overlays"
  defmacro unary_union(geometry) do
    quote do: fragment("ST_UnaryUnion(?, ?)", unquote(geometry))
  end
end
