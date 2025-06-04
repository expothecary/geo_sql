defmodule GeoSQL.PostGIS.Tiles.Layer do
  @enforce_keys [:name, :source, :columns]
  defstruct [:name, :source, :columns]

  @type column_name :: atom
  @type columns_definition :: %{geometry: column_name, id: column_name, tags: column_name}
  @type t :: %__MODULE__{
          name: String.t(),
          source: atom,
          columns: columns_definition
        }
end
