defmodule GeoSQL.PostGIS.Topo do
  @spec contains_properly(
          GeoSQL.geometry_input(),
          GeoSQL.geometry_input(),
          use_indexes? :: :with_indexes | :without_indexes
        ) :: GeoSQL.fragment()
  @doc group: "Relationships"
  defmacro contains_properly(geometryA, geometryB, use_indexes? \\ :with_indexes)

  defmacro contains_properly(geometryA, geometryB, :with_indexes) do
    quote do: fragment("ST_ContainsProperly(?,?)", unquote(geometryA), unquote(geometryB))
  end

  defmacro contains_properly(geometryA, geometryB, :without_indexes) do
    quote do: fragment("_ST_ContainsProperly(?,?)", unquote(geometryA), unquote(geometryB))
  end

  @spec line_crossing_direction(
          linestringA :: Geo.LineString.t() | GeoSQL.fragment(),
          linestringB :: Geo.LineString.t() | GeoSQL.fragment()
        ) ::
          GeoSQL.fragment()
  @doc group: "Relationships"
  defmacro line_crossing_direction(linestringA, linestringB) do
    quote do
      fragment("ST_LineCrossingDirection(?, ?)", unquote(linestringA), unquote(linestringB))
    end
  end
end
