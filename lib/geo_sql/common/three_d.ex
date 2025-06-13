defmodule GeoSQL.Common.ThreeD do
  @moduledoc "Non-standard but commonly implemented 3D functions"

  defmacro max_distance(geometryA, geometryB) do
    quote do: fragment("ST_3DMaxDistance(?,?)", unquote(geometryA), unquote(geometryB))
  end
end
