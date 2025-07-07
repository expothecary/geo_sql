defmodule GeoSQL.MM do
  @moduledoc """
  SQL/MM 2 functions that can used in ecto queries.

  ## Examples

      defmodule Example do
        import Ecto.Query
        use GeoSQL.MM

        def example_query(geom) do
          from location in Location, limit: 5, select: MM.distance(location.geom, ^geom)
        end
      end
  """

  defmacro __using__(_) do
    quote do
      require GeoSQL.MM
      require GeoSQL.MM.ThreeD
      require GeoSQL.MM.Topo
      alias GeoSQL.MM
    end
  end

  use GeoSQL.RepoUtils

  @spec area(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Measurement"
  defmacro area(geometry) do
    quote do: fragment("ST_Area(?)", unquote(geometry))
  end

  @spec as_binary(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Well-Known Binary (WKB)"
  defmacro as_binary(geometry) do
    quote do: fragment("ST_AsBinary(?)", unquote(geometry))
  end

  @spec as_text(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Well-Known Text (WKT)"
  defmacro as_text(geometry) do
    quote do: fragment("ST_AsText(?)", unquote(geometry))
  end

  @spec boundary(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro boundary(geometry) do
    quote do: fragment("ST_Boundary(?)", unquote(geometry))
  end

  @spec buffer(GeoSQL.geometry_input(), radius :: number) :: GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro buffer(geometry, radius) do
    quote do: fragment("ST_Buffer(?, ?)", unquote(geometry), unquote(radius))
  end

  @spec buffer(
          GeoSQL.geometry_input(),
          radius :: number,
          num_quarters_or_params :: number | String.t()
        ) ::
          GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro buffer(geometry, radius, num_quarters_or_params) do
    quote do
      fragment(
        "ST_Buffer(?, ?, ?)",
        unquote(geometry),
        unquote(radius),
        unquote(num_quarters_or_params)
      )
    end
  end

  @spec centroid(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro centroid(geometry) do
    quote do: fragment("ST_Centroid(?)", unquote(geometry))
  end

  @spec contains(GeoSQL.geometry_input(), contains :: GeoSQL.geometry_input()) ::
          GeoSQL.fragment()
  @doc group: "Topology Relationships"
  defmacro contains(geometry, contains) do
    quote do: fragment("ST_Contains(?,?)", unquote(geometry), unquote(contains))
  end

  @spec convex_hull(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro convex_hull(geometry) do
    quote do: fragment("ST_ConvexHull(?)", unquote(geometry))
  end

  @spec coord_dim(GeoSQL.geometry_input(), Ecto.Repo.t() | nil) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  @doc """
  Note: this function takes an optional Ecto.Repo parameter due to
  some backends implementing the non-standard ST_NDims rather than ST_CoordDim
  """
  defmacro coord_dim(geometry, repo \\ nil) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.SQLite3 ->
        quote do: fragment("ST_NDims(?)", unquote(geometry))

      _ ->
        quote do: fragment("ST_CoordDim(?)", unquote(geometry))
    end
  end

  @spec crosses(GeoSQL.geometry_input(), GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Topology Relationships"
  defmacro crosses(geometryA, geometryB) do
    quote do: fragment("ST_Crosses(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec curve_n(GeoSQL.geometry_input(), index :: integer | GeoSQL.geometry_input()) ::
          GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro curve_n(compound_curve, index) do
    quote do: fragment("ST_CurveN(?,?)", unquote(compound_curve), unquote(index))
  end

  @spec curve_to_line(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
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

  @spec difference(GeoSQL.geometry_input(), GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Overlays"
  defmacro difference(geometryA, geometryB) do
    quote do: fragment("ST_Difference(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec dimension(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro dimension(geometry) do
    quote do: fragment("ST_Dimension(?)", unquote(geometry))
  end

  @spec disjoint(GeoSQL.geometry_input(), GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Topology Relationships"
  defmacro disjoint(geometryA, geometryB) do
    quote do: fragment("ST_Disjoint(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec distance(GeoSQL.geometry_input(), GeoSQL.geometry_input(), in_meters :: boolean) ::
          GeoSQL.fragment()
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

  @spec equals(GeoSQL.geometry_input(), GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Topology Relationships"
  defmacro equals(geometryA, geometryB) do
    quote do: fragment("ST_Equals(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec end_point(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro end_point(geometry) do
    quote do: fragment("ST_EndPoint(?)", unquote(geometry))
  end

  @spec envelope(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro envelope(geometry) do
    quote do: fragment("ST_Envelope(?)", unquote(geometry))
  end

  @spec geometry_n(GeoSQL.geometry_input(), index :: pos_integer) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro geometry_n(geometry, index) do
    quote do: fragment("ST_GeometryN(?, ?)", unquote(geometry), unquote(index))
  end

  @spec geometry_type(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro geometry_type(geometry) do
    quote do: fragment("ST_GeometryType(?)", unquote(geometry))
  end

  defmacro gml_to_sql(geomgml) do
    quote do: fragment("ST_GMLToSQL(?)", unquote(geomgml))
  end

  defmacro gml_to_sql(geomgml, srid) do
    quote do: fragment("ST_GMLToSQL(?, ?)", unquote(geomgml), unquote(srid))
  end

  defmacro geom_from_text(text, srid \\ 0) do
    quote do: fragment("ST_GeomFromText(?,?)", unquote(text), unquote(srid))
  end

  @spec interior_ring_n(GeoSQL.geometry_input(), index :: pos_integer) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro interior_ring_n(geometry, index) do
    quote do: fragment("ST_InteriorRingN(?, ?)", unquote(geometry), unquote(index))
  end

  @spec intersection(GeoSQL.geometry_input(), GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Overlays"
  defmacro intersection(geometryA, geometryB) do
    quote do: fragment("ST_Intersection(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  @spec intersects(GeoSQL.geometry_input(), GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Topology Relationships"
  defmacro intersects(geometryA, geometryB) do
    quote do: fragment("ST_Intersects(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec is_closed(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro is_closed(geometry) do
    quote do: fragment("ST_IsClosed(?)", unquote(geometry))
  end

  defmacro is_empty(geometry) do
    quote do: fragment("ST_IsEmpty(?)", unquote(geometry))
  end

  @spec is_ring(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro is_ring(geometry) do
    quote do: fragment("ST_IsRing(?)", unquote(geometry))
  end

  @spec is_simple(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro is_simple(geometry) do
    quote do: fragment("ST_IsSimple(?)", unquote(geometry))
  end

  @spec is_valid(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Validation"
  defmacro is_valid(geometry) do
    quote do: fragment("ST_IsValid(?)", unquote(geometry))
  end

  @spec length(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Measurement"
  defmacro length(geometry) do
    quote do: fragment("ST_Length(?)", unquote(geometry))
  end

  @spec line_from_text(text :: String.t(), srid :: integer) :: GeoSQL.fragment()
  @doc group: "Well-Known Text (WKT)"
  defmacro line_from_text(text, srid \\ 0) do
    quote do: fragment("ST_LineFromText(?,?)", unquote(text), unquote(srid))
  end

  @spec line_from_text(text :: binary(), srid :: integer) :: GeoSQL.fragment()
  @doc group: "Well-Known Binary (WKB)"
  defmacro linestring_from_wkb(wkb, srid \\ 0) do
    quote do: fragment("ST_LineStringFromWKB(?,?)", unquote(wkb), unquote(srid))
  end

  @doc group: "Linear Referencing"
  defmacro locate_along(geometry, measure) do
    quote do
      fragment("ST_LocateAlong(?,?)", unquote(geometry), unquote(measure))
    end
  end

  @doc group: "Linear Referencing"
  defmacro locate_between(geometry, measure_start, measure_end) do
    quote do
      fragment(
        "ST_LocateBetween(?,?,?)",
        unquote(geometry),
        unquote(measure_start),
        unquote(measure_end)
      )
    end
  end

  @spec m(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro m(geometry) do
    quote do: fragment("ST_M(?)", unquote(geometry))
  end

  @spec m_point_from_text(text :: binary(), srid :: integer) :: GeoSQL.fragment()
  @doc group: "Well-Known Text (WKT)"
  defmacro m_point_from_text(text, srid \\ 0) do
    quote do: fragment("ST_MPointFromText(?, ?)", unquote(text), unquote(srid))
  end

  @spec m_line_from_text(text :: binary(), srid :: integer) :: GeoSQL.fragment()
  @doc group: "Well-Known Text (WKT)"
  defmacro m_line_from_text(text, srid \\ 0) do
    quote do: fragment("ST_MLineFromText(?, ?)", unquote(text), unquote(srid))
  end

  @spec m_poly_from_text(text :: binary(), srid :: integer) :: GeoSQL.fragment()
  @doc group: "Well-Known Text (WKT)"
  defmacro m_poly_from_text(text, srid \\ 0) do
    quote do: fragment("ST_MPolyFromText(?, ?)", unquote(text), unquote(srid))
  end

  @spec geom_collection_from_text(text :: binary(), srid :: integer) :: GeoSQL.fragment()
  @doc group: "Well-Known Text (WKT)"
  defmacro geom_collection_from_text(text, srid \\ 0) do
    quote do: fragment("ST_GeomCollFromText(?, ?)", unquote(text), unquote(srid))
  end

  @spec geom_from_wkb(text :: binary(), srid :: integer) :: GeoSQL.fragment()
  @doc group: "Well-Known Binary (WKB)"
  defmacro geom_from_wkb(bytea, srid \\ 0) do
    quote do: fragment("ST_GeomFromWKB(?, ?)", unquote(bytea), unquote(srid))
  end

  defmacro num_curves(curve) do
    quote do: fragment("ST_NumCurves(?)", unquote(curve))
  end

  defmacro num_patches(geometry) do
    quote do: fragment("ST_NumPatches(?)", unquote(geometry))
  end

  @spec num_geometries(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro num_geometries(geometry) do
    quote do: fragment("ST_NumGeometries(?)", unquote(geometry))
  end

  @spec num_interior_rings(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro num_interior_rings(geometry) do
    quote do: fragment("ST_NumInteriorRing(?)", unquote(geometry))
  end

  @spec num_points(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro num_points(geometry) do
    quote do: fragment("ST_NumPoints(?)", unquote(geometry))
  end

  defmacro ordering_equals(geometryA, geometryB) do
    quote do: fragment("ST_OrderingEquals(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec overlaps(GeoSQL.geometry_input(), GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Topology Relationships"
  defmacro overlaps(geometryA, geometryB) do
    quote do: fragment("ST_Overlaps(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro patch_n(geometry, face_index) do
    quote do: fragment("ST_PatchN(?,?)", unquote(geometry), unquote(face_index))
  end

  defmacro perimeter(geometry) do
    quote do: fragment("ST_Perimeter(?)", unquote(geometry))
  end

  defmacro perimeter(geography, srid) do
    quote do: fragment("ST_Perimeter(?,?)", unquote(geography), unquote(srid))
  end

  @spec point(x :: number, y :: number) :: GeoSQL.fragment()
  @doc group: "Geometry Constructors"
  defmacro point(x, y) do
    quote do: fragment("ST_Point(?, ?)", unquote(x), unquote(y))
  end

  @spec point_from_text(text :: binary(), srid :: integer) :: GeoSQL.fragment()
  @doc group: "Well-Known Text (WKT)"
  defmacro point_from_text(text, srid \\ 0) do
    quote do: fragment("ST_PointFromText(?, ?)", unquote(text), unquote(srid))
  end

  @spec point_from_wkb(text :: binary(), srid :: integer) :: GeoSQL.fragment()
  @doc group: "Well-Known Binary (WKB)"
  defmacro point_from_wkb(bytea, srid \\ 0) do
    quote do: fragment("ST_PointFromWKB(?, ?)", unquote(bytea), unquote(srid))
  end

  @spec point_n(GeoSQL.geometry_input(), index :: pos_integer) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro point_n(geometry, index) do
    quote do: fragment("ST_PointN(?, ?)", unquote(geometry), unquote(index))
  end

  @spec point_on_surface(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Processing"
  defmacro point_on_surface(geometry) do
    quote do: fragment("ST_PointOnSurface(?)", unquote(geometry))
  end

  @doc group: "Geometry Constructors"
  defmacro polygon(linestring, srid) do
    quote do: fragment("ST_Polygon(?,?)", unquote(linestring), unquote(srid))
  end

  @spec polygon_from_text(text :: binary(), srid :: integer) :: GeoSQL.fragment()
  @doc group: "Well-Known Text (WKT)"
  defmacro polygon_from_text(text, srid \\ 0) do
    quote do: fragment("ST_PolygonFromText(?, ?)", unquote(text), unquote(srid))
  end

  @spec relate(GeoSQL.geometry_input(), GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Topology Relationships"
  defmacro relate(geometryA, geometryB) do
    quote do: fragment("ST_Relate(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @type boundary_node_rule :: :ogc_mod2 | :endpoint | :multivalent_endpoint | :monovalent_endpoint
  @spec relate(
          GeoSQL.geometry_input(),
          GeoSQL.geometry_input(),
          matrix_or_rule :: String.t() | boundary_node_rule
        ) :: GeoSQL.fragment()
  @doc group: "Topology Relationships"
  defmacro relate(geometryA, geometryB, boundary_rule) when is_atom(boundary_rule) do
    rule_value =
      case boundary_rule do
        :ogc_mod2 -> 1
        :endpoint -> 2
        :multivalent_endpoint -> 3
        :monovalent_endpoint -> 4
      end

    quote do
      fragment(
        "ST_Relate(?,?,?)",
        unquote(geometryA),
        unquote(geometryB),
        unquote(rule_value)
      )
    end
  end

  defmacro relate(geometryA, geometryB, intersectionPatternMatrix) do
    quote do
      fragment(
        "ST_Relate(?,?,?)",
        unquote(geometryA),
        unquote(geometryB),
        unquote(intersectionPatternMatrix)
      )
    end
  end

  @spec srid(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Spatial Reference Systems"
  defmacro srid(geometry) do
    quote do: fragment("ST_SRID(?)", unquote(geometry))
  end

  @spec start_point(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro start_point(geometry) do
    quote do: fragment("ST_StartPoint(?)", unquote(geometry))
  end

  @spec sym_difference(GeoSQL.geometry_input(), GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Overlays"
  defmacro sym_difference(geometryA, geometryB) do
    quote do: fragment("ST_SymDifference(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec touches(GeoSQL.geometry_input(), GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Topology Relationships"
  defmacro touches(geometryA, geometryB) do
    quote do: fragment("ST_Touches(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec transform(geometry :: GeoSQL.geometry_input(), srid :: pos_integer()) :: GeoSQL.fragment()
  @doc group: "Affine Transforms"
  defmacro transform(geometry, srid) do
    quote do: fragment("ST_Transform(?, ?)", unquote(geometry), unquote(srid))
  end

  @spec union(geometryList :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Overlays"
  defmacro union(geometryList) do
    quote do: fragment("ST_Union(?)", unquote(geometryList))
  end

  @spec union(GeoSQL.geometry_input(), GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Overlays"
  defmacro union(geometryA, geometryB) do
    quote do: fragment("ST_Union(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec within(GeoSQL.geometry_input(), GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Topology Relationships"
  defmacro within(geometryA, geometryB) do
    quote do: fragment("ST_Within(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec x(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro x(geometry) do
    quote do: fragment("ST_X(?)", unquote(geometry))
  end

  @spec y(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro y(geometry) do
    quote do: fragment("ST_Y(?)", unquote(geometry))
  end

  @spec z(GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro z(geometry) do
    quote do: fragment("ST_Z(?)", unquote(geometry))
  end
end
