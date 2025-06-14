defmodule GeoSQL.PostGIS.Topo do
  @spec contains_properly(
          Geo.Geometry.t(),
          Geo.Geometry.t(),
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
end
