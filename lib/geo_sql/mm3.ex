defmodule GeoSQL.MM3 do
  @moduledoc """
  SQL/MM 3 functions that can used in ecto queries. This requires a GIS store implementation
  which implements these functions, such as PostGIS 3.
  """

  defmacro __using__(_) do
    quote do
      require GeoSQL.MM3
      require GeoSQL.MM3.ThreeD
      require GeoSQL.MM3.Topo
      alias GeoSQL.MM3
    end
  end

  defmacro coord_dim(geometry) do
    quote do: fragment("ST_CoordDim(?)", unquote(geometry))
  end

  defmacro curve(compound_curve, index) do
    quote do: fragment("ST_CurveN(?)", unquote(compound_curve), unquote(index))
  end

  defmacro curve_to_line(curve) do
    quote do: fragment("ST_CurveToLine(?)", unquote(curve))
  end

  defmacro curve_to_line(curve, tolerance, tolerance_type \\ 0, flags \\ 0) do
    quote do
      fragment(
        "ST_CurveToLine(?, ?, ?, ?)",
        unquote(curve),
        unquote(tolerance),
        unquote(tolerance_type),
        unquote(flags)
      )
    end
  end

  defmacro gml_to_sql(geomgml) do
    quote do: fragment("ST_GMLToSQL(?)", unquote(geomgml))
  end

  defmacro gml_to_sql(geomgml, srid) do
    quote do: fragment("ST_GMLToSQL(?, ?)", unquote(geomgml), unquote(srid))
  end

  defmacro geo_from_text(text, srid \\ 0) do
    quote do: fragment("ST_GeometryFromText(?,?)", unquote(text), unquote(srid))
  end

  defmacro is_empty(geometry) do
    quote do: fragment("ST_IsEmpty(?)", unquote(geometry))
  end

  defmacro locate_along(geometry, measure, offset \\ 0) do
    quote do
      fragment("ST_LocateAlong(?)", unquote(geometry), unquote(measure), unquote(offset))
    end
  end

  defmacro locate_between(geometry, measure_start, measure_end, offset \\ 0) do
    quote do
      fragment(
        "ST_LocateBetween(?)",
        unquote(geometry),
        unquote(measure_start),
        unquote(measure_end),
        unquote(offset)
      )
    end
  end

  defmacro num_curves(curve) do
    quote do: fragment("ST_NumCurves(?)", unquote(curve))
  end

  defmacro num_patches(geometry) do
    quote do: fragment("ST_NumPatches(?)", unquote(geometry))
  end

  defmacro ordering_equals(geometryA, geometryB) do
    quote do: fragment("ST_OrderingEquals(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro patch_n(geometry, face_index) do
    quote do: fragment("ST_PatchN(?, ?)", unquote(geometry), unquote(face_index))
  end

  defmacro perimeter(geometry) do
    quote do: fragment("ST_Perimeter(?)", unquote(geometry))
  end

  defmacro perimeter(geography, srid) do
    quote do: fragment("ST_Perimeter(?, ?)", unquote(geography), unquote(srid))
  end

  defmacro polygon(linestring, srid) do
    quote do: fragment("ST_Polygon(?, ?)", unquote(linestring), unquote(srid))
  end

  defmacro wkb_to_sql(text) do
    quote do: fragment("ST_WKBToSQL(?)", unquote(text))
  end

  defmacro wtk_to_sql(text) do
    quote do: fragment("ST_WKTToSQL(?)", unquote(text))
  end
end
