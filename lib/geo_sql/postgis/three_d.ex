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

  defmacro longest_line(geometryA, geometryB) do
    quote do: fragment("ST_3DLongestLine(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  @spec make_box(low_left_bottom :: Geo.Geometry.t(), high_right_top :: Geo.Geometry.t()) ::
          Ecto.Query.fragment()
  defmacro make_box(low_left_bottom, high_right_top) do
    quote do: fragment("ST_3DMakeBox(?,?)", unquote(low_left_bottom), unquote(high_right_top))
  end

  defmacro shortest_line(geometryA, geometryB) do
    quote do: fragment("ST_3DShortestLine(?,?)", unquote(geometryA), unquote(geometryB))
  end
end
