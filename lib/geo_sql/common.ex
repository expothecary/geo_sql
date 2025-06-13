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

  defmacro relate_match(matrix, pattern) when is_binary(matrix) and is_binary(pattern) do
    quote do: fragment("ST_Relatematch(?, ?)", unquote(matrix), unquote(pattern))
  end

  defmacro shift_longitude(geometry, repo) do
    case GeoSQL.repo_adapter(repo) do
      Ecto.Adapters.Postgres -> quote do: fragment("ST_ShiftLongitude(?)", unquote(geometry))
      _ -> quote do: fragment("ST_Shift_Longitude(?)", unquote(geometry))
    end
  end
end
