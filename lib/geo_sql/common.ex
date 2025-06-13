defmodule GeoSQL.Common do
  @moduledoc """
  This module contains common, but non-standard, GIS SQL functions. These are
  found in multiple database implementations, though they may differ in minor
  syntactical details in each implementation.

  Note that some backends may require to have special initialization or
  dependencies loaded for some of these functions to work. e.g. SpatialList
  must be built with the GEO package for some of these functions to be available.
  """

  defmacro __using__(_) do
    quote do
      require GeoSQL.Common
      require GeoSQL.Common.ThreeD
      alias GeoSQL.Common
    end
  end

  defmacro azimuth(originGeometry, targetGeometry) do
    quote do: fragment("ST_Azimuth(?,?)", unquote(originGeometry), unquote(targetGeometry))
  end

  @spec closest_point(Geo.Geometry.t(), Geo.Geometry.t(), spheroid? :: boolean, Ecto.Repo.t()) ::
          Ecto.Query.fragment()
  defmacro closest_point(geometryA, geometryB, spheroid? \\ false, repo \\ nil) do
    if spheroid? and repo != nil and GeoSQL.repo_adapter(repo) == Ecto.Adapters.Postgres do
      quote do: fragment("ST_ClosestPoint(?,?,true)", unquote(geometryA), unquote(geometryB))
    else
      quote do: fragment("ST_ClosestPoint(?,?)", unquote(geometryA), unquote(geometryB))
    end
  end

  @spec concave_hull(Geo.Geometry.t(), precision :: number(), allow_holes? :: boolean) ::
          Ecto.Query.fragment()
  defmacro concave_hull(geometry, precision \\ 1, allow_holes? \\ false)
           when precision >= 0 and precision <= 1 do
    quote do
      fragment(
        "ST_ConcaveHull(?,?,?)",
        unquote(geometry),
        unquote(precision),
        unquote(allow_holes?)
      )
    end
  end

  defmacro covers(geometryA, geometryB) do
    quote do: fragment("ST_Covers(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro covered_by(geometryA, geometryB) do
    quote do: fragment("ST_CoveredBy(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro collect(geometryList) do
    quote do: fragment("ST_Collect(?)", unquote(geometryList))
  end

  defmacro collect(geometryA, geometryB) do
    quote do: fragment("ST_Collect(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro bd_poly_from_text(wkt, srid) do
    quote do: fragment("ST_BdPolyFromText(?, ?)", unquote(wkt), unquote(srid))
  end

  defmacro bd_m_poly_from_text(wkt, srid) do
    quote do: fragment("ST_BdMPolyFromText(?, ?)", unquote(wkt), unquote(srid))
  end

  defmacro build_area(geometry) do
    quote do: fragment("ST_BuildArea(?)", unquote(geometry))
  end

  @spec flip_coordinates(Geo.Geometry.t(), Ecto.Repo.t() | nil) :: Ecto.Query.fragment()
  defmacro flip_coordinates(geometry, repo) do
    case GeoSQL.repo_adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_FlipCoordinate(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("ST_SwapCoordinates(?)", unquote(geometry))
    end
  end

  @spec largest_empty_circle(Geo.Geometry.t(), tolerance :: number(), Ecto.Repo.t() | nil) ::
          Ecto.Query.fragment()
  defmacro largest_empty_circle(geometry, tolerance \\ 0.0, repo \\ nil)
           when tolerance >= 0 and tolerance <= 1 do
    if repo != nil and GeoSQL.repo_adapter(repo) == Ecto.Adapters.SQLite3 do
      quote do: fragment("GEOSLargestEmptyCircle(?,?)", unquote(geometry), unquote(tolerance))
    else
      quote do: fragment("ST_LargestEmptyCircle(?,?)", unquote(geometry), unquote(tolerance))
    end
  end

  @spec line_merge(Geo.Geometry.t(), directed? :: boolean, Ecto.Repo.t() | nil) ::
          Ecto.Query.fragment()
  defmacro line_merge(geometryA, directed? \\ false, repo \\ nil) do
    if directed? and repo != nil and GeoSQL.repo_adapter(repo) == Ecto.Adapters.Postgres do
      quote do: fragment("ST_LineMerge(?,?,true)", unquote(geometryA))
    else
      quote do: fragment("ST_LineMerge(?,?)", unquote(geometryA))
    end
  end

  defmacro make_valid(geometry) do
    quote do: fragment("ST_MakeValid(?)", unquote(geometry))
  end

  defmacro make_point(x, y, repo) do
    case GeoSQL.repo_adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MakePoint(?, ?)", unquote(x), unquote(y))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("MakePoint(?, ?)", unquote(x), unquote(y))
    end
  end

  defmacro make_point(x, y, z, repo) do
    case GeoSQL.repo_adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MakePoint(?, ?, ?)", unquote(x), unquote(y), unquote(z))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("MakePoint(?, ?, ?)", unquote(x), unquote(y), unquote(z))
    end
  end

  defmacro make_point(x, y, z, m, repo) do
    case GeoSQL.repo_adapter(repo) do
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

  defmacro max_distance(geometryA, geometryB) do
    quote do: fragment("ST_MaxDistance(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec maximum_inscribed_circle(Geo.Geometry.t(), Ecto.Repo.t() | nil) :: Ecto.Query.fragment()
  defmacro maximum_inscribed_circle(geometry, repo \\ nil) do
    if repo != nil and GeoSQL.repo_adapter(repo) == Ecto.Adapters.SQLite3 do
      quote do: fragment("GEOSMaximumInscribedCircle(?)", unquote(geometry))
    else
      quote do: fragment("ST_MaximumInscribedCircle(?)", unquote(geometry))
    end
  end

  @spec minimum_bounding_circle(Geo.Geometry.t(), Ecto.Repo.t() | nil) :: Ecto.Query.fragment()
  defmacro minimum_bounding_circle(geometry, repo \\ nil) do
    if repo != nil and GeoSQL.repo_adapter(repo) == Ecto.Adapters.SQLite3 do
      quote do: fragment("GEOSMinimumBoundingCircle(?)", unquote(geometry))
    else
      quote do: fragment("ST_MinimumBoundingCircle(?)", unquote(geometry))
    end
  end

  @spec minimum_bounding_radius(Geo.Geometry.t(), Ecto.Repo.t() | nil) :: Ecto.Query.fragment()
  defmacro minimum_bounding_radius(geometry, repo \\ nil) do
    if repo != nil and GeoSQL.repo_adapter(repo) == Ecto.Adapters.SQLite3 do
      quote do: fragment("GEOSMinimumBoundingRadius(?)", unquote(geometry))
    else
      quote do: fragment("ST_MinimumBoundingRadius(?)", unquote(geometry))
    end
  end

  defmacro minimum_clearance(geometry, repo) do
    case GeoSQL.repo_adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MinimumClearance(?)", unquote(geometry))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GEOSMinimumClearance(?)", unquote(geometry))
    end
  end

  defmacro minimum_clearance_line(geometry, repo) do
    case GeoSQL.repo_adapter(repo) do
      Ecto.Adapters.Postgres ->
        quote do: fragment("ST_MinimumClearanceLine(?)", unquote(geometry))

      Ecto.Adapters.SQLite3 ->
        quote do: fragment("GEOSMinimumClearanceLine(?)", unquote(geometry))
    end
  end

  defmacro node(geometry) do
    quote do: fragment("ST_Node(?)", unquote(geometry))
  end

  defmacro oriented_envelope(geometry) do
    quote do: fragment("ST_OrientedEnvelope(?)", unquote(geometry))
  end

  defmacro offset_curve(line, distance) when is_number(distance) do
    quote do: fragment("ST_OffsetCurve(?,?)", unquote(line), unquote(distance))
  end

  defmacro polygonize(geometry) do
    quote do: fragment("ST_Polygonize(?)", unquote(geometry))
  end

  defmacro reduce_precision(geometry, grid_size) when is_number(grid_size) do
    quote do: fragment("ST_ReducePrecision(?, ?)", unquote(geometry), unquote(grid_size))
  end

  defmacro relate_match(matrix, pattern) when is_binary(matrix) and is_binary(pattern) do
    quote do: fragment("ST_Relatematch(?, ?)", unquote(matrix), unquote(pattern))
  end

  defmacro rotate(geometry, rotate_radians, repo \\ nil) when is_number(rotate_radians) do
    if repo != nil and GeoSQL.repo_adapter(repo) == Ecto.Adapters.SQLite3 do
      degrees_per_radian = 57.2958
      degrees = rotate_radians * degrees_per_radian
      quote do: fragment("RotateCoordinates(?, ?)", unquote(geometry), unquote(degrees))
    else
      quote do: fragment("ST_Rotate(?, ?)", unquote(geometry), unquote(rotate_radians))
    end
  end

  @spec scale(Geo.Geometry.t(), scale_x :: number, scale_y :: number, Ecto.Repo.t() | nil) ::
          Ecto.Query.fragment()
  defmacro scale(geometry, scale_x, scale_y, repo \\ nil)
           when is_number(scale_x) and is_number(scale_y) do
    if repo != nil and GeoSQL.repo_adapter(repo) == Ecto.Adapters.SQLite3 do
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

  defmacro shared_paths(geometryA, geometryB) do
    quote do: fragment("ST_SharedPaths(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  @spec shift_longitude(Geo.Geometry.t(), Ecto.Repo.t()) :: Ecto.Query.fragment()
  defmacro shift_longitude(geometry, repo) do
    case GeoSQL.repo_adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_ShiftLongitude(?)", unquote(geometry))
      _ -> quote do: fragment("ST_Shift_Longitude(?)", unquote(geometry))
    end
  end

  @spec shortest_line(
          Geo.Geometry.t(),
          Geo.Geometry.t(),
          spheroid? :: boolean,
          Ecto.Repo.t() | nil
        ) ::
          Ecto.Query.fragment()
  defmacro shortest_line(geometryA, geometryB, spheroid? \\ false, repo \\ nil) do
    if spheroid? and repo != nil and GeoSQL.repo_adapter(repo) == Ecto.Adapters.Postgres do
      quote do: fragment("ST_ShortestLine(?,?,true)", unquote(geometryA), unquote(geometryB))
    else
      quote do: fragment("ST_ShortestLine(?,?)", unquote(geometryA), unquote(geometryB))
    end
  end

  defmacro simplify(geometry, tolerance) when is_number(tolerance) do
    quote do: fragment("ST_Simplify(?, ?)", unquote(geometry), unquote(tolerance))
  end

  defmacro simplify_preserve_topology(geometry, tolerance) when is_number(tolerance) do
    quote do: fragment("ST_SimplifyPreserveTopology(?, ?)", unquote(geometry), unquote(tolerance))
  end

  defmacro split(inputGeometry, bladeGeometry) do
    quote do: fragment("ST_Split(?, ?)", unquote(inputGeometry), unquote(bladeGeometry))
  end

  defmacro subdivide(geometry, max_vertices \\ 256) do
    quote do: fragment("ST_Subdivide(?, ?)", unquote(geometry), unquote(max_vertices))
  end

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

  @spec triangulate_polygon(Geo.Geometry.t(), Ecto.Repo.t() | nil) :: Ecto.Query.fragment()
  defmacro triangulate_polygon(geometry, repo \\ nil) do
    if repo != nil and GeoSQL.repo_adapter(repo) == Ecto.Adapters.SQLite3 do
      quote do: fragment("ConstrainedDelaunayTriangulation(?)", unquote(geometry))
    else
      quote do: fragment("ST_TriangulatePolygon()", unquote(geometry))
    end
  end

  defmacro unary_union(geometry) do
    quote do: fragment("ST_UnaryUnion(?, ?)", unquote(geometry))
  end
end
