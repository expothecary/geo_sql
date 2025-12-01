defmodule GeoSQL.PostGIS do
  @moduledoc """
    Non-standard GIS functions found in PostGIS.
  """

  defmacro __using__(_) do
    quote do
      require GeoSQL.PostGIS
      require GeoSQL.PostGIS.Operators
      require GeoSQL.PostGIS.ThreeD
      require GeoSQL.PostGIS.Topo
      require GeoSQL.PostGIS.VectorTiles
      alias GeoSQL.PostGIS
    end
  end

  @spec affine(
          GeoSQL.geometry_input(),
          a :: number,
          b :: number,
          c :: number,
          d :: number,
          e :: number,
          f :: number,
          g :: number,
          h :: number,
          i :: number,
          x_offset :: number,
          y_offset :: number,
          z_offset :: number
        ) :: GeoSQL.fragment()
  @doc group: "Affine Transformations"
  defmacro affine(geometry, a, b, c, d, e, f, g, h, i, x_offset, y_offset, z_offset) do
    quote do
      fragment(
        "ST_Affine(?,?,?,?,?,?,?,?,?,?,?,?,?)",
        unquote(geometry),
        unquote(a),
        unquote(b),
        unquote(c),
        unquote(d),
        unquote(e),
        unquote(f),
        unquote(g),
        unquote(h),
        unquote(i),
        unquote(x_offset),
        unquote(y_offset),
        unquote(z_offset)
      )
    end
  end

  @doc group: "Affine Transformations"
  @spec affine(
          GeoSQL.geometry_input(),
          a :: number,
          b :: number,
          d :: number,
          e :: number,
          x_offset :: number,
          y_offset :: number
        ) :: GeoSQL.fragment()
  defmacro affine(geometry, a, b, d, e, x_offset, y_offset) do
    quote do
      fragment(
        "ST_Affine(?,?,?,?,?,?,?)",
        unquote(geometry),
        unquote(a),
        unquote(b),
        unquote(d),
        unquote(e),
        unquote(x_offset),
        unquote(y_offset)
      )
    end
  end

  @doc group: "Measurement"
  defmacro angle(vectorAPoint1, vectorAPoint2, vectorBPoint1, vectorBPoint2) do
    quote do
      fragment(
        "ST_Angle(?,?,?,?)",
        unquote(vectorAPoint1),
        unquote(vectorAPoint2),
        unquote(vectorBPoint1),
        unquote(vectorBPoint2)
      )
    end
  end

  @doc group: "Measurement"
  defmacro angle(point1, midpoint, point2) do
    quote do
      fragment(
        "ST_Angle(?,?,?)",
        unquote(point1),
        unquote(midpoint),
        unquote(point2)
      )
    end
  end

  @doc group: "Measurement"
  defmacro angle(lineA, lineB) do
    quote do: fragment("ST_Angle(?,?)", unquote(lineA), unquote(lineB))
  end

  @spec bounding_diagonal(
          GeoSQL.geometry_input(),
          best_fit? :: boolean
        ) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro bounding_diagonal(geometry, best_fit? \\ false) do
    quote do: fragment("ST_BoundingDiagonal(?,?)", unquote(geometry), unquote(best_fit?))
  end

  @spec collection_homogenize(collection :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro collection_homogenize(collection) do
    quote do: fragment("ST_CollectionHomogenize(?)", unquote(collection))
  end

  @spec contains_properly(
          GeoSQL.geometry_input(),
          GeoSQL.geometry_input(),
          use_indexes? :: :with_indexes | :without_indexes
        ) :: GeoSQL.fragment()
  @doc group: "Topology Relationships"
  defmacro contains_properly(geometryA, geometryB, use_indexes? \\ :with_indexes)

  defmacro contains_properly(geometryA, geometryB, :with_indexes) do
    quote do: fragment("ST_ContainsProperly(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro contains_properly(geometryA, geometryB, :without_indexes) do
    quote do: fragment("_ST_ContainsProperly(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Distance Relationships"
  defmacro d_within(geometryA, geometryB, float, return_value \\ :by_srid)

  defmacro d_within(geometryA, geometryB, float, :by_srid) do
    quote do
      fragment("ST_DWithin(?,?,?)", unquote(geometryA), unquote(geometryB), unquote(float))
    end
  end

  @doc group: "Distance Relationships"
  defmacro d_within(geometryA, geometryB, float, use_spheroid) when is_boolean(use_spheroid) do
    quote do
      fragment(
        "ST_DWithin(?::geography, ?::geography, ?)",
        unquote(geometryA),
        unquote(geometryB),
        unquote(float),
        unquote(use_spheroid)
      )
    end
  end

  @doc group: "Distance Relationships"
  defmacro d_fully_within(geometryA, geometryB, distance) when is_number(distance) do
    quote do
      fragment(
        "ST_DFullyWithin(?,?,?)",
        unquote(geometryA),
        unquote(geometryB),
        unquote(distance)
      )
    end
  end

  @doc group: "Measurement"
  defmacro distance_sphere(geometryA, geometryB) do
    quote do: fragment("ST_DistanceSphere(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Geometry Accessors"
  @spec dump(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  defmacro dump(geometry) do
    quote do: fragment("ST_Dump(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  @spec dump_points(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  defmacro dump_points(geometry) do
    quote do: fragment("ST_DumpPoints(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  @spec dump_segments(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  defmacro dump_segments(geometry) do
    quote do: fragment("ST_DumpSegments(?)", unquote(geometry))
  end

  @doc group: "Geometry Accessors"
  @spec dump_rings(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  defmacro dump_rings(geometry) do
    quote do: fragment("ST_DumpRings(?)", unquote(geometry))
  end

  @spec expand(
          geometry :: GeoSQL.geometry_input(),
          dx :: number,
          dy :: number
        ) :: GeoSQL.fragment()
  @doc group: "Bounding Boxes"
  defmacro expand(geometry, dx, dy) do
    quote do: fragment("ST_Expand(?,?,?)", unquote(geometry), unquote(dx), unquote(dy))
  end

  @spec expand(
          geometry :: GeoSQL.geometry_input(),
          dx :: number,
          dy :: number,
          dz :: number
        ) :: GeoSQL.fragment()
  @doc group: "Bounding Boxes"
  defmacro expand(geometry, dx, dy, dz) do
    quote do
      fragment("ST_Expand(?,?,?)", unquote(geometry), unquote(dx), unquote(dy), unquote(dz))
    end
  end

  @spec expand(
          geometry :: GeoSQL.geometry_input(),
          dx :: number,
          dy :: number,
          dz :: number,
          dm :: number
        ) :: GeoSQL.fragment()
  @doc group: "Bounding Boxes"
  defmacro expand(geometry, dx, dy, dz, dm) do
    quote do
      fragment(
        "ST_Expand(?,?,?)",
        unquote(geometry),
        unquote(dx),
        unquote(dy),
        unquote(dz),
        unquote(dm)
      )
    end
  end

  @doc group: "Geometry Processing"
  defmacro generate_points(geometryA, npoints) do
    quote do: fragment("ST_GeneratePoints(?,?)", unquote(geometryA), unquote(npoints))
  end

  @doc group: "Geometry Processing"
  defmacro generate_points(geometry, npoints, seed) do
    quote do
      fragment(
        "ST_GeneratePoints(?,?,?)",
        unquote(geometry),
        unquote(npoints),
        unquote(seed)
      )
    end
  end

  @spec has_arc(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro has_arc(geometry) do
    quote do: fragment("ST_HasArc(?)", unquote(geometry))
  end

  @spec has_m(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro has_m(geometry) do
    quote do: fragment("ST_HasM(?)", unquote(geometry))
  end

  @spec has_z(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro has_z(geometry) do
    quote do: fragment("ST_HasZ(?)", unquote(geometry))
  end

  @spec is_collection(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro is_collection(geometry) do
    quote do: fragment("ST_IsCollection(?)", unquote(geometry))
  end

  @spec inverse_transform_pipeline(
          GeoSQL.geometry_input(),
          pipeline :: String.t(),
          srid :: pos_integer
        ) :: GeoSQL.fragment()
  @doc group: "Spatial Reference Systems"
  defmacro inverse_transform_pipeline(geometry, pipeline, srid) do
    quote do
      fragment(
        "ST_InverseTransformPipeline(?,?,?)",
        unquote(geometry),
        unquote(pipeline),
        unquote(srid)
      )
    end
  end

  @spec line_crossing_direction(
          linestringA :: Geometry.LineString.t() | GeoSQL.geometry_input(),
          linestringB :: Geometry.LineString.t() | GeoSQL.geometry_input()
        ) ::
          GeoSQL.fragment()
  @doc group: "Topology Relationships"
  defmacro line_crossing_direction(linestringA, linestringB) do
    quote do
      fragment("ST_LineCrossingDirection(?, ?)", unquote(linestringA), unquote(linestringB))
    end
  end

  @spec line_to_curve(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro line_to_curve(geometry) do
    quote do: fragment("ST_LineToCurve(?)", unquote(geometry))
  end

  @doc group: "Linear Referencing"
  @doc "PostGIS extension to `locate_along` with an offset"
  defmacro locate_along(geometry, measure, offset \\ 0) do
    quote do
      fragment("ST_LocateAlong(?,?,?)", unquote(geometry), unquote(measure), unquote(offset))
    end
  end

  @doc group: "Linear Referencing"
  @doc "PostGIS extension to `locate_between` with an offset"
  defmacro locate_between(geometry, measure_start, measure_end, offset) do
    quote do
      fragment(
        "ST_LocateBetween(?,?,?,?)",
        unquote(geometry),
        unquote(measure_start),
        unquote(measure_end),
        unquote(offset)
      )
    end
  end

  @doc group: "Linear Referencing"
  @spec locate_between_elevations(
          GeoSQL.geometry_input(),
          elevation_start :: number,
          elevation_end :: number
        ) ::
          GeoSQL.fragment()
  defmacro locate_between_elevations(geometry, elevation_start, elevation_end)
           when is_number(elevation_start) and is_number(elevation_end) do
    quote do
      fragment(
        "ST_LocateBetweenElevations(?,?,?)",
        unquote(geometry),
        unquote(elevation_start),
        unquote(elevation_end)
      )
    end
  end

  @doc group: "Measurement"
  defmacro longest_line(geometryA, geometryB) do
    quote do: fragment("ST_LongestLine(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Bounding Boxes"
  defmacro make_box_2d(geometryA, geometryB) do
    quote do: fragment("ST_MakeBox2D(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  @doc group: "Geometry Constructors"
  defmacro make_envelope(xMin, yMin, xMax, yMax) do
    quote do
      fragment(
        "ST_MakeEnvelope(?, ?, ?, ?)",
        unquote(xMin),
        unquote(yMin),
        unquote(xMax),
        unquote(yMax)
      )
    end
  end

  @doc group: "Geometry Constructors"
  defmacro make_envelope(xMin, yMin, xMax, yMax, srid) do
    quote do
      fragment(
        "ST_MakeEnvelope(?, ?, ?, ?, ?)",
        unquote(xMin),
        unquote(yMin),
        unquote(xMax),
        unquote(yMax),
        unquote(srid)
      )
    end
  end

  @doc group: "Geometry Validation"
  defmacro make_valid(geometry, params) do
    quote do: fragment("ST_MakeValid(?, ?)", unquote(geometry), unquote(params))
  end

  @doc group: "Overlays"
  defmacro mem_union(geometryList) do
    quote do: fragment("ST_MemUnion(?)", unquote(geometryList))
  end

  @spec mem_size(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro mem_size(geometry) do
    quote do: fragment("ST_MemSize(?)", unquote(geometry))
  end

  @spec normalize(geometry :: GeoSQL.geometry_input()) :: GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro normalize(geometry) do
    quote do: fragment("ST_Normalize(?)", unquote(geometry))
  end

  @spec points(GeoSQL.Geometry.t()) :: GeoSQL.fragment()
  @doc group: "Geometry Accessors"
  defmacro points(geometry) do
    quote do: fragment("ST_Points(?)", unquote(geometry))
  end

  @type quantize_coordinate :: :x | :y | :z | :m
  @type quantize_precision :: [{quantize_coordinate, number}]
  @spec quantize_coordinates(geometry :: GeoSQL.geometry_input(), quantize_precision) ::
          GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro quantize_coordinates(geometry, precisions) do
    x = Keyword.get(precisions, :x, 0)
    y = Keyword.get(precisions, :y, x)
    z = Keyword.get(precisions, :z, x)
    m = Keyword.get(precisions, :m, x)

    quote do
      fragment(
        "ST_QuantizeCoordinates(?,?,?,?,?)",
        unquote(geometry),
        unquote(x),
        unquote(y),
        unquote(z),
        unquote(m)
      )
    end
  end

  @spec remove_irrelevant_points_for_view(
          geometry :: GeoSQL.geometry_input(),
          bbox_bounds :: GeoSQL.geometry_input(),
          cartesian? :: boolean
        ) ::
          GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro remove_irrelevant_points_for_view(geometry, bbox_bounds, cartesian? \\ false) do
    quote do
      fragment(
        "ST_RemoveIrrelevantPointsForView(?, ?, ?)",
        unquote(geometry),
        unquote(bbox_bounds),
        unquote(cartesian?)
      )
    end
  end

  @spec remove_small_parts(
          geometry :: GeoSQL.geometry_input(),
          minSizeX :: number,
          minSizeY :: number
        ) ::
          GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro remove_small_parts(geometry, minSizeX, minSizeY \\ false) do
    quote do
      fragment(
        "ST_RemoveSmallParts(?, ?, ?)",
        unquote(geometry),
        unquote(minSizeX),
        unquote(minSizeY)
      )
    end
  end

  @doc group: "Affine Transformations"
  defmacro rotate(geometry, rotate_radians) do
    quote do: fragment("ST_Rotate(?, ?)", unquote(geometry), unquote(rotate_radians))
  end

  @doc group: "Affine Transformations"
  defmacro rotate(geometry, rotate_radians, origin_point) do
    quote do
      fragment(
        "ST_Rotate(?, ?, ?)",
        unquote(geometry),
        unquote(rotate_radians),
        unquote(origin_point)
      )
    end
  end

  @doc group: "Affine Transformations"
  defmacro rotate_x(geometry, rotate_radians) do
    quote do: fragment("ST_RotateX(?, ?)", unquote(geometry), unquote(rotate_radians))
  end

  @doc group: "Affine Transformations"
  defmacro rotate_y(geometry, rotate_radians) do
    quote do: fragment("ST_RotateY(?, ?)", unquote(geometry), unquote(rotate_radians))
  end

  @doc group: "Affine Transformations"
  defmacro rotate_z(geometry, rotate_radians) do
    quote do: fragment("ST_RotateZ(?, ?)", unquote(geometry), unquote(rotate_radians))
  end

  @spec scale(GeoSQL.geometry_input(), scale :: GeoSQL.geometry_input()) :: GeoSQL.fragment()

  @doc group: "Affine Transformations"
  defmacro scale(geometry, scale_by) do
    quote do: fragment("ST_Scale(?,?)", unquote(geometry), unquote(scale_by))
  end

  @spec scale(
          GeoSQL.geometry_input(),
          scale :: GeoSQL.geometry_input(),
          origin :: GeoSQL.geometry_input()
        ) ::
          GeoSQL.fragment()
  @doc group: "Affine Transformations"
  defmacro scale(geometry, scale_by, origin) do
    quote do: fragment("ST_Scale(?,?,?)", unquote(geometry), unquote(scale_by), unquote(origin))
  end

  @spec scale(GeoSQL.geometry_input(), scale_x :: number, scale_y :: number, scale_z :: number) ::
          GeoSQL.fragment()
  @doc group: "Affine Transformations"
  defmacro scale(geometry, scale_x, scale_y, scale_z)
           when is_number(scale_x) and is_number(scale_y) and is_number(scale_z) do
    quote do
      fragment(
        "ST_Scale(?,?,?,?)",
        unquote(geometry),
        unquote(scale_x),
        unquote(scale_y),
        unquote(scale_z)
      )
    end
  end

  @spec scroll(linestring :: GeoSQL.geometry_input(), point :: GeoSQL.geometry_input()) ::
          GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro scroll(linestring, point) do
    quote do: fragment("ST_Scroll(?, ?)", unquote(linestring), unquote(point))
  end

  @doc group: "Geometry Accessors"
  defmacro summary(geometry) do
    quote do: fragment("ST_Summary(?)", unquote(geometry))
  end

  @doc group: "Geometry Editors"
  defmacro swap_ordinates(geometry, ordinates) do
    quote do: fragment("ST_SwapOrdinates(?)", unquote(geometry), unquote(ordinates))
  end

  @spec trans_scale(
          GeoSQL.geometry_input(),
          translate_x :: number,
          translate_y :: number,
          scale_x :: number,
          scale_y :: number
        ) ::
          GeoSQL.fragment()
  @doc group: "Affine Transformations"
  defmacro trans_scale(geometry, translate_x, translate_y, scale_x, scale_y)
           when is_number(translate_x) and
                  is_number(translate_y) and
                  is_number(scale_x) and
                  is_number(scale_y) do
    quote do
      fragment(
        "ST_TransScale(?,?,?,?,?)",
        unquote(geometry),
        unquote(translate_x),
        unquote(translate_y),
        unquote(scale_x),
        unquote(scale_y)
      )
    end
  end

  @spec wrap_x(geometry :: GeoSQL.geometry_input(), wrap :: number, move :: number) ::
          GeoSQL.fragment()
  @doc group: "Geometry Editors"
  defmacro wrap_x(geometry, wrap, move) do
    quote do: fragment("ST_WrapX(?,?,?)", unquote(geometry), unquote(wrap), unquote(move))
  end

  @doc group: "Geometry Accessors"
  defmacro zm_flag(geometry) do
    quote do: fragment("ST_Zmflag(?)", unquote(geometry))
  end
end
