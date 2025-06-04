defmodule GeoSQL.PostGIS do
  @moduledoc """
    Non-standard GIS functions found in PostGIS.
  """

  defmacro __using__(_) do
    quote do
      require GeoSQL.PostGIS
      alias GeoSQL.PostGIS
    end
  end

  defmacro as_mvt(rows) do
    quote do: fragment("ST_AsMVT(?)", unquote(rows))
  end

  defmacro as_mvt(rows, options) do
    allowed = [:name, :extent, :geom_name, :feature_id_name]

    {param_string, params} =
      as_positional_params(options, allowed)

    template = "ST_AsMVT(? #{param_string})"

    quote do
      fragment(
        unquote(template),
        unquote(rows),
        unquote_splicing(params)
      )
    end
  end

  defmacro as_mvt_geom(geometry, bounds) do
    quote do: fragment("ST_AsMVTGeom(?, ?)", unquote(geometry), unquote(bounds))
  end

  defmacro as_mvt_geom(geometry, bounds, options) do
    allowed = [:extent, :buffer, :clip_geom]
    {param_string, params} = as_positional_params(options, allowed)
    template = "ST_AsMVTGeom(?, ? #{param_string})"

    quote do
      fragment(
        unquote(template),
        unquote(geometry),
        unquote(bounds),
        unquote_splicing(params)
      )
    end
  end

  defmacro distance_sphere(geometryA, geometryB) do
    quote do: fragment("ST_DistanceSphere(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro dwithin(geometryA, geometryB, float, return_value \\ :by_srid)

  defmacro dwithin(geometryA, geometryB, float, :by_srid) do
    quote do
      fragment("ST_DWithin(?,?,?)", unquote(geometryA), unquote(geometryB), unquote(float))
    end
  end

  defmacro dwithin(geometryA, geometryB, float, use_spheroid) when is_boolean(use_spheroid) do
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

  defmacro tile_envelope(zoom, x, y) do
    quote do
      fragment(
        "ST_TileEnvelope(?, ?, ?)",
        unquote(zoom),
        unquote(x),
        unquote(y)
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

  defmacro tile_envelope(zoom, x, y, bounds, margin \\ 0.0) do
    quote do
      fragment(
        "ST_TileEnvelope(?, ?, ?, ?, ?)",
        unquote(zoom),
        unquote(x),
        unquote(y),
        unquote(bounds),
        unquote(margin)
      )
    end
  end

  defmacro swap_ordinates(geometry, ordinates) when is_binary(ordinates) do
    quote do: fragment("ST_SwapOrdinates(?)", unquote(geometry), unquote(ordinates))
  end

  @spec as_positional_params(options :: Keyword.t(), allowed_keys :: [:atom]) ::
          {param_string :: String.t(), params :: list}
  def as_positional_params(options, allowed_keys)
      when is_list(options) and is_list(allowed_keys) do
    values =
      Enum.reduce_while(allowed_keys, [], fn key, acc ->
        case Keyword.get(options, key) do
          nil -> {:halt, acc}
          value -> {:cont, [value | acc]}
        end
      end)

    {String.duplicate(", ?", Enum.count(values)), Enum.reverse(values)}
  end

  @spec as_named_params(options :: Keyword.t(), allowed_keys :: [:atom]) ::
          {param_string :: String.t(), params :: list}
  def as_named_params(options, allowed_keys) when is_list(options) and is_list(allowed_keys) do
    Keyword.validate!(options, allowed_keys)

    {
      Enum.map(options, fn {key, _value} -> "#{key} => ?" end) |> Enum.join(", "),
      Enum.map(options, fn {_key, value} -> value end)
    }
  end
end
