defmodule GeoSQL.PostGIS.Operators do
  @moduledoc """
    Non-standard GIS operators found in PostGIS.

    These are often more optimized and/or specialized than their ST_* equivalents.
  """

  defmacro bbox_equals?(geometryA, geometryB) do
    quote do: fragment("? ~= ?", unquote(geometryA), unquote(geometryB))
  end

  defmacro bbox_intersects?(geometryA, geometryB) do
    quote do: fragment("? && ?", unquote(geometryA), unquote(geometryB))
  end

  defmacro contained_by?(geometryA, geometryB) do
    quote do: fragment("? @ ?", unquote(geometryA), unquote(geometryB))
  end

  defmacro contains?(geometryA, geometryB) do
    quote do: fragment("? ~ ?", unquote(geometryA), unquote(geometryB))
  end

  defmacro equal?(geometryA, geometryB) do
    quote do: fragment("? = ?", unquote(geometryA), unquote(geometryB))
  end

  defmacro nd_bbox_intersects?(geometryA, geometryB) do
    quote do: fragment("? &&& ?", unquote(geometryA), unquote(geometryB))
  end

  defmacro overlaps_or_to_the?(direction, geometryA, geometryB) do
    operator =
      case direction do
        :above -> "|&>"
        :below -> "&<|"
        :left -> "&<"
        :right -> "&>"
      end

    quote do: fragment("? ? ?", unquote(geometryA), unquote(operator), unquote(geometryB))
  end

  defmacro strictly_to_the?(direction, geometryA, geometryB) do
    operator =
      case direction do
        :above -> "|>>"
        :below -> "<<|"
        :left -> "<<"
        :right -> ">>"
      end

    quote do: fragment("? ? ?", unquote(geometryA), unquote(operator), unquote(geometryB))
  end
end
