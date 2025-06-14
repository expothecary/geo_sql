defmodule GeoSQL.Common.Topo do
  @moduledoc "Non-standard but commonly implemented topology functions"

  @doc group: "Relationships"
  defmacro relate_match(matrix, pattern) when is_binary(matrix) and is_binary(pattern) do
    quote do: fragment("ST_Relatematch(?, ?)", unquote(matrix), unquote(pattern))
  end

  @spec get_edge_by_point(topology :: String.t(), point :: GeoSQL.Geometry.t(), tolerance :: number) ::
          GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_edge_by_point(topology, point, tolerance) do
    quote do
      fragment(
        "?.ST_GetFaceEdges(?, ?)",
        unquote(topology),
        unquote(point),
        unquote(tolerance)
      )
    end
  end
end
