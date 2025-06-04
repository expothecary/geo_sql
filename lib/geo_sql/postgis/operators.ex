defmodule GeoSQL.PostGIS.Operators do
  @moduledoc """
    Non-standard GIS operators found in PostGIS.

    These are often more optimized and/or specialized than their ST_* equivalents.
  """

  defmacro bbox_intersects?(geometryA, geometryB) do
    quote do: fragment("? && ?", unquote(geometryA), unquote(geometryB))
  end

  defmacro nd_bbox_intersects?(geometryA, geometryB) do
    quote do: fragment("? &&& ?", unquote(geometryA), unquote(geometryB))
  end

  defmacro overlaps_or_left?(geometryA, geometryB) do
    quote do: fragment("? &&& ?", unquote(geometryA), unquote(geometryB))
  end
end
