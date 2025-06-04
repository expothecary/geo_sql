defmodule GeoSQL.PostGIS.Tiles.Layer do
  defstruct [:name, :source, :columns]

  @type column_name :: atom
  @type t :: %__MODULE__{
          name: String.t(),
          source: atom,
          columns: %{geometry: column_name, id: column_name, tags: column_name}
        }
end
