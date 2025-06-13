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

  @spec concave_hull(Geo.Geometry.t(), precision :: float(), allow_holes? :: boolean) ::
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

  defmacro build_area(geometryA) do
    quote do: fragment("ST_BuildArea(?)", unquote(geometryA))
  end

  defmacro flip_coordinates(geometry, repo) do
    case GeoSQL.repo_adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_FlipCoordinate(?)", unquote(geometry))
      Ecto.Adapters.SQLite3 -> quote do: fragment("ST_SwapCoordinates(?)", unquote(geometry))
    end
  end

  defmacro node(geometry) do
    quote do: fragment("ST_Node(?)", unquote(geometry))
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
        quote do:
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

      Ecto.Adapters.SQLite3 ->
        quote do:
                fragment(
                  "MakePointZM(?, ?, ?, ?)",
                  unquote(x),
                  unquote(y),
                  unquote(z),
                  unquote(m)
                )
    end
  end

  defmacro max_distance(geometryA, geometryB) do
    quote do: fragment("ST_MaxDistance(?,?)", unquote(geometryA), unquote(geometryB))
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

  defmacro relate_match(matrix, pattern) when is_binary(matrix) and is_binary(pattern) do
    quote do: fragment("ST_Relatematch(?, ?)", unquote(matrix), unquote(pattern))
  end

  @spec shift_longitude(Geo.Geometry.t(), Ecto.Repo.t()) :: Ecto.Query.fragment()
  defmacro shift_longitude(geometry, repo) do
    case GeoSQL.repo_adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_ShiftLongitude(?)", unquote(geometry))
      _ -> quote do: fragment("ST_Shift_Longitude(?)", unquote(geometry))
    end
  end

  @spec shortest_line(Geo.Geometry.t(), Geo.Geometry.t(), spheroid? :: boolean, Ecto.Repo.t()) ::
          Ecto.Query.fragment()
  defmacro shortest_line(geometryA, geometryB, spheroid?, repo) do
    if spheroid? and repo != nil and GeoSQL.repo_adapter(repo) == Ecto.Adapters.Postgres do
      quote do: fragment("ST_ShortestLine(?,?,true)", unquote(geometryA), unquote(geometryB))
    else
      quote do: fragment("ST_ShortestLine(?,?)", unquote(geometryA), unquote(geometryB))
    end
  end

  defmacro split(inputGeometry, bladeGeometry) do
    quote do: fragment("ST_Split(?, ?)", unquote(inputGeometry), unquote(bladeGeometry))
  end

  defmacro subdivide(geometry, max_vertices \\ 256) do
    quote do: fragment("ST_Subdivide(?, ?)", unquote(geometry), unquote(max_vertices))
  end

  defmacro unary_union(geometry) do
    quote do: fragment("ST_UnaryUnion(?, ?)", unquote(geometry))
  end
end
