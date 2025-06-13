defmodule GeoSQL.PostGIS.ThreeD do
  @moduledoc "Non-standard PostGIS 3D functions"

  @spec closest_point(geometryA :: Geo.Geometry.t(), geometryB :: Geo.Geometry.t()) ::
          Ecto.Query.fragment()
  defmacro closest_point(geometryA, geometryB) do
    quote do: fragment("ST_3DClosestPoint(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec d_fully_within(
          geometryA :: Geo.Geometry.t(),
          geometryB :: Geo.Geometry.t(),
          distance :: number
        ) ::
          Ecto.Query.fragment()
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

  @spec extent(geometryA :: Geo.Geometry.t()) :: Ecto.Query.fragment()
  defmacro extent(geometry) do
    quote do: fragment("ST_3DExtent(?)", unquote(geometry))
  end

  @spec line_interpolate_point(line :: Geo.Geometry.t(), fraction :: number) ::
          Ecto.Query.fragment()
  defmacro line_interpolate_point(line, fraction)
           when is_number(fraction) and fraction <= 1.0 and fraction >= 0 do
    quote do: fragment("ST_3DLineInterpolatePoint(?,?)", unquote(line), unquote(fraction))
  end

  @spec longest_line(geometryA :: Geo.Geometry.t(), geometryB :: Geo.Geometry.t()) ::
          Ecto.Query.fragment()
  defmacro longest_line(geometryA, geometryB) do
    quote do: fragment("ST_3DLongestLine(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  @spec make_box(low_left_bottom :: Geo.Geometry.t(), high_right_top :: Geo.Geometry.t()) ::
          Ecto.Query.fragment()
  defmacro make_box(low_left_bottom, high_right_top) do
    quote do: fragment("ST_3DMakeBox(?,?)", unquote(low_left_bottom), unquote(high_right_top))
  end

  @spec shortest_line(geometryA :: Geo.Geometry.t(), geometryB :: Geo.Geometry.t()) ::
          Ecto.Query.fragment()
  defmacro shortest_line(geometryA, geometryB) do
    quote do: fragment("ST_3DShortestLine(?,?)", unquote(geometryA), unquote(geometryB))
  end
end
