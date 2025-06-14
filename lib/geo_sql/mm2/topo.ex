defmodule GeoSQL.MM2.Topo do
  @moduledoc """
  SQL/MM2 Topological functions prefixed with `ST_` in the standard.

  May require additional dependencies and configuration in the GIS store. For example,
  PostGIS requires the SFCGAL backend for some topological functions.
  """

  @doc group: "Relationships"
  defmacro contains(geometryA, geometryB) do
    quote do: fragment("ST_Contains(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Relationships"
  defmacro crosses(geometryA, geometryB) do
    quote do: fragment("ST_Crosses(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Relationships"
  defmacro disjoint(geometryA, geometryB) do
    quote do: fragment("ST_Disjoint(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Relationships"
  defmacro equals(geometryA, geometryB) do
    quote do: fragment("ST_Equals(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Relationships"
  defmacro intersects(geometryA, geometryB) do
    quote do: fragment("ST_Intersects(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Relationships"
  defmacro overlaps(geometryA, geometryB) do
    quote do: fragment("ST_Overlaps(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Relationships"
  defmacro relate(geometryA, geometryB) do
    quote do: fragment("ST_Relate(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Relationships"
  defmacro relate(geometryA, geometryB, intersectionPatternMatrix) do
    quote do:
            fragment(
              "ST_Relate(?,?,?)",
              unquote(geometryA),
              unquote(geometryB),
              unquote(intersectionPatternMatrix)
            )
  end

  @doc group: "Relationships"
  defmacro touches(geometryA, geometryB) do
    quote do: fragment("ST_Touches(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Relationships"
  defmacro within(geometryA, geometryB) do
    quote do: fragment("ST_Within(?,?)", unquote(geometryA), unquote(geometryB))
  end
end
