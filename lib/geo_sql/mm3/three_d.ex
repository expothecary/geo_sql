defmodule GeoSQL.MM3.ThreeD do
  @moduledoc """
  SQL/MM3 3D functions prefixed with `ST_3D` or `CG_3D` in the standard which can be used in ecto queries.

  This may require additional dependencies and configuration in the GIS store. For example,
  PostGIS requires the SFCGAL backend for some of these functions.
  """

  defmacro area(geometry) do
    quote do: fragment("CG_3DArea(?)", unquote(geometry))
  end

  defmacro difference(geometryA, geometryB) do
    quote do: fragment("CG_3DDifference(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro distance(geometryA, geometryB) do
    # There is also a CG_3DDiference in PostGIS but it does not seem to be in a bare-bones build?
    quote do: fragment("ST_3DDistance(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro intersection(geometryA, geometryB) do
    quote do: fragment("CG_3DIntersection(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro intersects(geometryA, geometryB) do
    # There is also a CG_3DIntersects in PostGIS but it does not seem to be in a bare-bones build?
    quote do: fragment("ST_3DIntersects(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro length(geometryA) do
    quote do: fragment("ST_3DLength(?)", unquote(geometryA))
  end

  defmacro perimeter(geometryA) do
    quote do: fragment("ST_3DPerimeter(?)", unquote(geometryA))
  end

  defmacro union(geometrySet) do
    quote do: fragment("CG_3DUnion(?)", unquote(geometrySet))
  end

  defmacro union(geometryA, geometryB) do
    quote do: fragment("CG_3DUnion(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro volume(geometry) do
    quote do: fragment("CG_Volume(?)", unquote(geometry))
  end

  defmacro within(geometryA, geometryB, distance) do
    quote do
      fragment("ST_3DDWithin(?)", unquote(geometryA), unquote(geometryB), unquote(distance))
    end
  end
end
