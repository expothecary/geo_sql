defmodule GeoSQL.MM2 do
  @moduledoc """
  SQL/MM 2 functions that can used in ecto queries.
  The module is named after the prefix of the functions in raw SQL: `ST_`.


  ## Examples

      defmodule Example do
        import Ecto.Query
        import GeoSQL.MM2

        def example_query(geom) do
          from location in Location, limit: 5, select: distance(location.geom, ^geom)
        end
      end
  """

  defmacro __using__(_) do
    quote do
      require GeoSQL.MM2
      alias GeoSQL.MM2
    end
  end

  defmacro area(geometry) do
    quote do: fragment("ST_Area(?)", unquote(geometry))
  end

  defmacro as_binary(geometry) do
    quote do: fragment("ST_AsBinary(?)", unquote(geometry))
  end

  defmacro srid(geometry) do
    quote do: fragment("ST_SRID(?)", unquote(geometry))
  end

  defmacro as_text(geometry) do
    quote do: fragment("ST_AsText(?)", unquote(geometry))
  end

  defmacro boundary(geometry) do
    quote do: fragment("ST_Boundary(?)", unquote(geometry))
  end

  defmacro buffer(geometry, double) do
    quote do: fragment("ST_Buffer(?, ?)", unquote(geometry), unquote(double))
  end

  defmacro buffer(geometry, double, integer) do
    quote do: fragment("ST_Buffer(?, ?, ?)", unquote(geometry), unquote(double), unquote(integer))
  end

  defmacro centroid(geometry) do
    quote do: fragment("ST_Centroid(?)", unquote(geometry))
  end

  defmacro contains(geometryA, geometryB) do
    quote do: fragment("ST_Contains(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro convex_hull(geometry) do
    quote do: fragment("ST_ConvexHull(?)", unquote(geometry))
  end

  defmacro crosses(geometryA, geometryB) do
    quote do: fragment("ST_Crosses(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro difference(geometryA, geometryB) do
    quote do: fragment("ST_Difference(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro dimension(geometry) do
    quote do: fragment("ST_Dimension(?)", unquote(geometry))
  end

  defmacro disjoint(geometryA, geometryB) do
    quote do: fragment("ST_Disjoint(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro distance(geometryA, geometryB, in_meters \\ false) do
    if in_meters do
      quote do
        fragment(
          "ST_Distance(?::geography, ?::geography)",
          unquote(geometryA),
          unquote(geometryB)
        )
      end
    else
      quote do: fragment("ST_Distance(?,?)", unquote(geometryA), unquote(geometryB))
    end
  end

  defmacro end_point(geometry) do
    quote do: fragment("ST_EndPoint(?)", unquote(geometry))
  end

  defmacro envelope(geometry) do
    quote do: fragment("ST_Envelope(?)", unquote(geometry))
  end

  defmacro equals(geometryA, geometryB) do
    quote do: fragment("ST_Equals(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro geom_from_text(text, srid \\ -1) do
    quote do: fragment("ST_GeomFromText(?, ?)", unquote(text), unquote(srid))
  end

  defmacro geometry_n(geometry, int) do
    quote do: fragment("ST_GeometryN(?, ?)", unquote(geometry), unquote(int))
  end

  defmacro geometry_type(geometry) do
    quote do: fragment("ST_GeometryType(?)", unquote(geometry))
  end

  defmacro interior_ring_n(geometry, int) do
    quote do: fragment("ST_InteriorRingN(?, ?)", unquote(geometry), unquote(int))
  end

  defmacro intersects(geometryA, geometryB) do
    quote do: fragment("ST_Intersects(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro intersection(geometryA, geometryB) do
    quote do: fragment("ST_Intersection(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro is_closed(geometry) do
    quote do: fragment("ST_IsClosed(?)", unquote(geometry))
  end

  defmacro is_ring(geometry) do
    quote do: fragment("ST_IsRing(?)", unquote(geometry))
  end

  defmacro is_simple(geometry) do
    quote do: fragment("ST_IsSimple(?)", unquote(geometry))
  end

  defmacro length(geometry) do
    quote do: fragment("ST_Length(?)", unquote(geometry))
  end

  defmacro line_from_text(text, srid \\ -1) do
    quote do: fragment("ST_LineFromText(?, ?)", unquote(text), unquote(srid))
  end

  defmacro is_valid(geometry) do
    quote do: fragment("ST_IsValid(?)", unquote(geometry))
  end

  defmacro line_from_wkb(bytea, srid \\ -1) do
    quote do: fragment("ST_LineFromWKB(?, ?)", unquote(bytea), unquote(srid))
  end

  defmacro linestring_from_wkb(bytea, srid \\ -1) do
    quote do: fragment("ST_LinestringFromWKB(?, ?)", unquote(bytea), unquote(srid))
  end

  defmacro m(geometry) do
    quote do: fragment("ST_M(?)", unquote(geometry))
  end

  defmacro m_point_from_text(text, srid \\ -1) do
    quote do: fragment("ST_MPointFromText(?, ?)", unquote(text), unquote(srid))
  end

  defmacro m_line_from_text(text, srid \\ -1) do
    quote do: fragment("ST_MLineFromText(?, ?)", unquote(text), unquote(srid))
  end

  defmacro m_poly_from_text(text, srid \\ -1) do
    quote do: fragment("ST_MPolyFromText(?, ?)", unquote(text), unquote(srid))
  end

  defmacro m_geom_coll_from_text(text, srid \\ -1) do
    quote do: fragment("ST_GeomCollFromText(?, ?)", unquote(text), unquote(srid))
  end

  defmacro m_geom_from_wkb(bytea, srid \\ -1) do
    quote do: fragment("ST_GeomFromWKB(?, ?)", unquote(bytea), unquote(srid))
  end

  defmacro num_geometries(geometry) do
    quote do: fragment("ST_NumGeometries(?)", unquote(geometry))
  end

  defmacro num_interior_rings(geometry) do
    quote do: fragment("ST_NumInteriorRings(?)", unquote(geometry))
  end

  defmacro num_interior_ring(geometry) do
    quote do: fragment("ST_NumInteriorRing(?)", unquote(geometry))
  end

  defmacro num_points(geometry) do
    quote do: fragment("ST_NumPoints(?)", unquote(geometry))
  end

  defmacro overlaps(geometryA, geometryB) do
    quote do: fragment("ST_Overlaps(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro point(x, y) do
    quote do: fragment("ST_Point(?, ?)", unquote(x), unquote(y))
  end

  defmacro point_from_text(text, srid \\ -1) do
    quote do: fragment("ST_PointFromText(?, ?)", unquote(text), unquote(srid))
  end

  defmacro point_from_wkb(bytea, srid \\ -1) do
    quote do: fragment("ST_PointFromWKB(?, ?)", unquote(bytea), unquote(srid))
  end

  defmacro point_n(geometry, int) do
    quote do: fragment("ST_PointN(?, ?)", unquote(geometry), unquote(int))
  end

  defmacro point_on_surface(geometry) do
    quote do: fragment("ST_PointOnSurface(?)", unquote(geometry))
  end

  defmacro polygon_from_text(text, srid \\ -1) do
    quote do: fragment("ST_PolygonFromText(?, ?)", unquote(text), unquote(srid))
  end

  defmacro relate(geometryA, geometryB) do
    quote do: fragment("ST_Relate(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro relate(geometryA, geometryB, intersectionPatternMatrix) do
    quote do:
            fragment(
              "ST_Relate(?,?,?)",
              unquote(geometryA),
              unquote(geometryB),
              unquote(intersectionPatternMatrix)
            )
  end

  defmacro start_point(geometry) do
    quote do: fragment("ST_StartPoint(?)", unquote(geometry))
  end

  defmacro sym_difference(geometryA, geometryB) do
    quote do: fragment("ST_SymDifference(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro touches(geometryA, geometryB) do
    quote do: fragment("ST_Touches(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro transform(wkt, srid) do
    quote do: fragment("ST_Transform(?, ?::integer)", unquote(wkt), unquote(srid))
  end

  defmacro union(geometryList) do
    quote do: fragment("ST_Union(?)", unquote(geometryList))
  end

  defmacro union(geometryA, geometryB) do
    quote do: fragment("ST_Union(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro within(geometryA, geometryB) do
    quote do: fragment("ST_Within(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro x(geometry) do
    quote do: fragment("ST_X(?)", unquote(geometry))
  end

  defmacro y(geometry) do
    quote do: fragment("ST_Y(?)", unquote(geometry))
  end

  defmacro z(geometry) do
    quote do: fragment("ST_Z(?)", unquote(geometry))
  end
end
