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
          Geo.Geometry.t(),
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
  defmacro affine(geometry, a, b, c, d, e, f, g, h, i, x_offset, y_offset, z_offset) do
    quote do
      fragment(
        "ST_Affine(?,?,?,?,?,?,?,?,?,?,?)",
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

  @spec affine(
          Geo.Geometry.t(),
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

  defmacro angle(geometryA, geometryB) do
    quote do: fragment("ST_Angle(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro contains_properly(geometryA, geometryB, use_indexes? \\ :with_indexes)

  defmacro contains_properly(geometryA, geometryB, :with_indexes) do
    quote do: fragment("ST_ContainsProperly(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro contains_properly(geometryA, geometryB, :without_indexes) do
    quote do: fragment("_ST_ContainsProperly(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro distance_sphere(geometryA, geometryB) do
    quote do: fragment("ST_DistanceSphere(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro d_within(geometryA, geometryB, float, return_value \\ :by_srid)

  defmacro d_within(geometryA, geometryB, float, :by_srid) do
    quote do
      fragment("ST_DWithin(?,?,?)", unquote(geometryA), unquote(geometryB), unquote(float))
    end
  end

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

  defmacro generate_points(geometryA, npoints) do
    quote do: fragment("ST_GeneratePoints(?,?)", unquote(geometryA), unquote(npoints))
  end

  defmacro generate_points(geometryA, npoints, seed) do
    quote do
      fragment(
        "ST_GeneratePoints(?,?,?)",
        unquote(geometryA),
        unquote(npoints),
        unquote(seed)
      )
    end
  end

  defmacro line_crossing_direction(linestringA, linestringB) do
    quote do
      fragment("ST_LineCrossingDirection(?, ?)", unquote(linestringA), unquote(linestringB))
    end
  end

  @spec locate_between_elevations(
          Geo.Geometry.t(),
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

  defmacro longest_line(geometryA, geometryB) do
    quote do: fragment("ST_LongestLine(?, ?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro make_box_2d(geometryA, geometryB) do
    quote do: fragment("ST_MakeBox2D(?, ?)", unquote(geometryA), unquote(geometryB))
  end

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

  defmacro make_valid(geometry, params) do
    quote do: fragment("ST_MakeValid(?, ?)", unquote(geometry), unquote(params))
  end

  defmacro mem_union(geometryList) do
    quote do: fragment("ST_MemUnion(?)", unquote(geometryList))
  end

  defmacro rotate(geometry, rotate_radians) when is_float(rotate_radians) do
    quote do: fragment("ST_Rotate(?, ?)", unquote(geometry), unquote(rotate_radians))
  end

  defmacro rotate(geometry, rotate_radians, origin_point) when is_float(rotate_radians) do
    quote do
      fragment(
        "ST_Rotate(?, ?, ?)",
        unquote(geometry),
        unquote(rotate_radians),
        unquote(origin_point)
      )
    end
  end

  defmacro rotate_x(geometry, rotate_radians) when is_float(rotate_radians) do
    quote do: fragment("ST_RotateX(?, ?)", unquote(geometry), unquote(rotate_radians))
  end

  defmacro rotate_y(geometry, rotate_radians) when is_float(rotate_radians) do
    quote do: fragment("ST_RotateY(?, ?)", unquote(geometry), unquote(rotate_radians))
  end

  defmacro rotate_z(geometry, rotate_radians) when is_float(rotate_radians) do
    quote do: fragment("ST_RotateZ(?, ?)", unquote(geometry), unquote(rotate_radians))
  end

  @spec scale(Geo.Geometry.t(), scale :: Geo.Geometry.t()) :: GeoSQL.fragment()
  defmacro scale(geometry, scale_by) do
    quote do: fragment("ST_Scale(?,?)", unquote(geometry), unquote(scale_by))
  end

  @spec scale(Geo.Geometry.t(), scale :: Geo.Geometry.t(), origin :: Geo.Geometry.t()) ::
          GeoSQL.fragment()
  defmacro scale(geometry, scale_by, origin) do
    quote do: fragment("ST_Scale(?,?,?)", unquote(geometry), unquote(scale_by), unquote(origin))
  end

  @spec scale(Geo.Geometry.t(), scale_x :: number, scale_y :: number, scale_z :: number) ::
          GeoSQL.fragment()
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

  defmacro set_srid(geometry, srid) do
    quote do: fragment("ST_SetSRID(?, ?)", unquote(geometry), unquote(srid))
  end

  defmacro swap_ordinates(geometry, ordinates) when is_binary(ordinates) do
    quote do: fragment("ST_SwapOrdinates(?)", unquote(geometry), unquote(ordinates))
  end

  @spec trans_scale(
          Geo.Geometry.t(),
          translate_x :: number,
          translate_y :: number,
          scale_x :: number,
          scale_y :: number
        ) ::
          GeoSQL.fragment()
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
end
