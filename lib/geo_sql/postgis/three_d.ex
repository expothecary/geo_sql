defmodule GeoSQL.PostGIS.ThreeD do
  @moduledoc "Non-standard PostGIS 3D functions"

  defmacro closest_point(geometryA, geometryB) do
    quote do: fragment("ST_3DClosestPoint(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro d_fully_within(geometryA, geometryB, distance) when is_number(distance) do
    quote do
      fragment(
        "ST_3DDFullyWithin(?,?,?)",
        unquote(geometryA),
        unquote(geometryB),
        unquote(distance)
      )
    end
  end
end
