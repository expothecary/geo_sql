defmodule GeoSQL.PostGIS do
  @moduledoc """
    Non-standard GIS functions found in PostGIS.
  """

  defmacro __using__(_) do
    quote do
      require GeoSQL.PostGIS
      require GeoSQL.PostGIS.Operators
      require GeoSQL.PostGIS.VectorTiles
      require GeoSQL.PostGIS.ThreeD
      alias GeoSQL.PostGIS
    end
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

  defmacro extent(geometry) do
    quote do: fragment("ST_EXTENT(?)::geometry", unquote(geometry))
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

  defmacro set_srid(geometry, srid) do
    quote do: fragment("ST_SetSRID(?, ?)", unquote(geometry), unquote(srid))
  end

  defmacro swap_ordinates(geometry, ordinates) when is_binary(ordinates) do
    quote do: fragment("ST_SwapOrdinates(?)", unquote(geometry), unquote(ordinates))
  end
end
