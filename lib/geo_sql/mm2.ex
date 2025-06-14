defmodule GeoSQL.MM2 do
  @moduledoc """
  SQL/MM 2 functions that can used in ecto queries.

  ## Examples

      defmodule Example do
        import Ecto.Query
        use GeoSQL.MM2

        def example_query(geom) do
          from location in Location, limit: 5, select: MM2.distance(location.geom, ^geom)
        end
      end
  """

  defmacro __using__(_) do
    quote do
      require GeoSQL.MM2
      alias GeoSQL.MM2
    end
  end

  @doc group: "Measurement"
  defmacro area(geometry) do
    quote do: fragment("ST_Area(?)", unquote(geometry))
  end

  @doc group: "Well-Known Binary (WKB)"
  defmacro as_binary(geometry) do
    quote do: fragment("ST_AsBinary(?)", unquote(geometry))
  end

  @doc group: "Well-Known Text (WKT)"
  defmacro as_text(geometry) do
    quote do: fragment("ST_AsText(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro boundary(geometry) do
    quote do: fragment("ST_Boundary(?)", unquote(geometry))
  end

  @doc group: "Geometry Processing"
  defmacro buffer(geometry, double) do
    quote do: fragment("ST_Buffer(?, ?)", unquote(geometry), unquote(double))
  end

  @doc group: "Geometry Processing"
  defmacro buffer(geometry, double, integer) do
    quote do: fragment("ST_Buffer(?, ?, ?)", unquote(geometry), unquote(double), unquote(integer))
  end

  @doc group: "Geometry Processing"
  defmacro centroid(geometry) do
    quote do: fragment("ST_Centroid(?)", unquote(geometry))
  end

  @doc group: "Topology Relationships"
  defmacro contains(geometryA, geometryB) do
    quote do: fragment("ST_Contains(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Geometry Processing"
  defmacro convex_hull(geometry) do
    quote do: fragment("ST_ConvexHull(?)", unquote(geometry))
  end

  @doc group: "Topology Relationships"
  defmacro crosses(geometryA, geometryB) do
    quote do: fragment("ST_Crosses(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc gropu: "Overlays"
  defmacro difference(geometryA, geometryB) do
    quote do: fragment("ST_Difference(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro dimension(geometry) do
    quote do: fragment("ST_Dimension(?)", unquote(geometry))
  end

  @doc group: "Topology Relationships"
  defmacro disjoint(geometryA, geometryB) do
    quote do: fragment("ST_Disjoint(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Measurement"
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

  @doc group: "Topology Relationships"
  defmacro equals(geometryA, geometryB) do
    quote do: fragment("ST_Equals(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Geometry Accessors"
  defmacro end_point(geometry) do
    quote do: fragment("ST_EndPoint(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro envelope(geometry) do
    quote do: fragment("ST_Envelope(?)", unquote(geometry))
  end

  @doc group: "Well-Known Text (WKT)"
  defmacro geom_from_text(text, srid \\ -1) do
    quote do: fragment("ST_GeomFromText(?, ?)", unquote(text), unquote(srid))
  end

  @doc group: "Geometry Accessors"
  defmacro geometry_n(geometry, int) do
    quote do: fragment("ST_GeometryN(?, ?)", unquote(geometry), unquote(int))
  end

  @doc group: "Geometry Accessors"
  defmacro geometry_type(geometry) do
    quote do: fragment("ST_GeometryType(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro interior_ring_n(geometry, int) do
    quote do: fragment("ST_InteriorRingN(?, ?)", unquote(geometry), unquote(int))
  end

  @doc group: "Overlays"
  defmacro intersection(geometryA, geometryB) do
    quote do: fragment("ST_Intersection(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Topology Relationships"
  defmacro intersects(geometryA, geometryB) do
    quote do: fragment("ST_Intersects(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Geometry Accessors"
  defmacro is_closed(geometry) do
    quote do: fragment("ST_IsClosed(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro is_ring(geometry) do
    quote do: fragment("ST_IsRing(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro is_simple(geometry) do
    quote do: fragment("ST_IsSimple(?)", unquote(geometry))
  end

  @doc group: "Measurement"
  defmacro length(geometry) do
    quote do: fragment("ST_Length(?)", unquote(geometry))
  end

  @doc group: "Well-Known Text (WKT)"
  defmacro line_from_text(text, srid \\ -1) do
    quote do: fragment("ST_LineFromText(?, ?)", unquote(text), unquote(srid))
  end

  @doc group: "Geometry Validation"
  defmacro is_valid(geometry) do
    quote do: fragment("ST_IsValid(?)", unquote(geometry))
  end

  @doc group: "Well-Known Binary (WKB)"
  defmacro line_from_wkb(bytea, srid \\ -1) do
    quote do: fragment("ST_LineFromWKB(?, ?)", unquote(bytea), unquote(srid))
  end

  @doc group: "Well-Known Binary (WKB)"
  defmacro linestring_from_wkb(bytea, srid \\ -1) do
    quote do: fragment("ST_LinestringFromWKB(?, ?)", unquote(bytea), unquote(srid))
  end

  @doc group: "Geometry Accessors"
  defmacro m(geometry) do
    quote do: fragment("ST_M(?)", unquote(geometry))
  end

  @doc group: "Well-Known Text (WKT)"
  defmacro m_point_from_text(text, srid \\ -1) do
    quote do: fragment("ST_MPointFromText(?, ?)", unquote(text), unquote(srid))
  end

  @doc group: "Well-Known Text (WKT)"
  defmacro m_line_from_text(text, srid \\ -1) do
    quote do: fragment("ST_MLineFromText(?, ?)", unquote(text), unquote(srid))
  end

  @doc group: "Well-Known Text (WKT)"
  defmacro m_poly_from_text(text, srid \\ -1) do
    quote do: fragment("ST_MPolyFromText(?, ?)", unquote(text), unquote(srid))
  end

  @doc group: "Well-Known Text (WKT)"
  defmacro m_geom_colletion_from_text(text, srid \\ -1) do
    quote do: fragment("ST_GeomCollFromText(?, ?)", unquote(text), unquote(srid))
  end

  @doc group: "Well-Known Binary (WKB)"
  defmacro m_geom_from_wkb(bytea, srid \\ -1) do
    quote do: fragment("ST_GeomFromWKB(?, ?)", unquote(bytea), unquote(srid))
  end

  @doc group: "Geometry Accessors"
  defmacro num_geometries(geometry) do
    quote do: fragment("ST_NumGeometries(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro num_interior_rings(geometry) do
    quote do: fragment("ST_NumInteriorRings(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro num_points(geometry) do
    quote do: fragment("ST_NumPoints(?)", unquote(geometry))
  end

  @doc group: "Topology Relationships"
  defmacro overlaps(geometryA, geometryB) do
    quote do: fragment("ST_Overlaps(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Geometry Constructors"
  defmacro point(x, y) do
    quote do: fragment("ST_Point(?, ?)", unquote(x), unquote(y))
  end

  @doc group: "Well-Known Text (WKT)"
  defmacro point_from_text(text, srid \\ -1) do
    quote do: fragment("ST_PointFromText(?, ?)", unquote(text), unquote(srid))
  end

  @doc group: "Well-Known Binary (WKB)"
  defmacro point_from_wkb(bytea, srid \\ -1) do
    quote do: fragment("ST_PointFromWKB(?, ?)", unquote(bytea), unquote(srid))
  end

  @doc group: "Geometry Accessors"
  defmacro point_n(geometry, int) do
    quote do: fragment("ST_PointN(?, ?)", unquote(geometry), unquote(int))
  end

  @doc group: "Geometry Processing"
  defmacro point_on_surface(geometry) do
    quote do: fragment("ST_PointOnSurface(?)", unquote(geometry))
  end

  @doc group: "Well-Known Text (WKT)"
  defmacro polygon_from_text(text, srid \\ -1) do
    quote do: fragment("ST_PolygonFromText(?, ?)", unquote(text), unquote(srid))
  end

  @doc group: "Topology Relationships"
  defmacro relate(geometryA, geometryB) do
    quote do: fragment("ST_Relate(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Topology Relationships"
  defmacro relate(geometryA, geometryB, intersectionPatternMatrix) do
    quote do:
            fragment(
              "ST_Relate(?,?,?)",
              unquote(geometryA),
              unquote(geometryB),
              unquote(intersectionPatternMatrix)
            )
  end

  @doc group: "Spatial Reference Systems"
  defmacro srid(geometry) do
    quote do: fragment("ST_SRID(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro start_point(geometry) do
    quote do: fragment("ST_StartPoint(?)", unquote(geometry))
  end

  @doc group: "Overlays"
  defmacro sym_difference(geometryA, geometryB) do
    quote do: fragment("ST_SymDifference(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Topology Relationships"
  defmacro touches(geometryA, geometryB) do
    quote do: fragment("ST_Touches(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Affine Transforms"
  defmacro transform(wkt, srid) do
    quote do: fragment("ST_Transform(?, ?::integer)", unquote(wkt), unquote(srid))
  end

  @doc group: "Overlays"
  defmacro union(geometryList) do
    quote do: fragment("ST_Union(?)", unquote(geometryList))
  end

  @doc group: "Overlays"
  defmacro union(geometryA, geometryB) do
    quote do: fragment("ST_Union(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Topology Relationships"
  defmacro within(geometryA, geometryB) do
    quote do: fragment("ST_Within(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Geometry Accessors"
  defmacro x(geometry) do
    quote do: fragment("ST_X(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro y(geometry) do
    quote do: fragment("ST_Y(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  defmacro z(geometry) do
    quote do: fragment("ST_Z(?)", unquote(geometry))
  end
end
