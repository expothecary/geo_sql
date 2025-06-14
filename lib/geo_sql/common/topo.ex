defmodule GeoSQL.Common.Topo do
  @moduledoc "Non-standard but commonly implemented topology functions"

  defmacro relate_match(matrix, pattern) when is_binary(matrix) and is_binary(pattern) do
    quote do: fragment("ST_Relatematch(?, ?)", unquote(matrix), unquote(pattern))
  end
end
