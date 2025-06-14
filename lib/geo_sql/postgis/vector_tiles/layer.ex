defmodule GeoSQL.PostGIS.VectorTiles.Layer do
  @enforce_keys [:name, :source, :columns]
  defstruct [
    :name,
    :source,
    :columns,
    prefix: nil,
    srid: 4326,
    compose_query_fn: &__MODULE__.identity_composer/1
  ]

  @type column_name :: atom
  @type columns_definition :: %{geometry: column_name, id: column_name, tags: column_name}
  @type t :: %__MODULE__{
          name: String.t(),
          source: String.t(),
          prefix: String.t() | nil,
          columns: columns_definition,
          compose_query_fn: (Ecto.Query.t() -> Ecto.Query.t())
        }

  def identity_composer(query), do: query
end
