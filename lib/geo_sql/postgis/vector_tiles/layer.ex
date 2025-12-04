defmodule GeoSQL.PostGIS.VectorTiles.Layer do
  @moduledoc "A vector tile layer."
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

  @typedoc """
  The columns to load from a table to populate the `geometry`, `id`, and `tags` fields
  in the resulting vector tile layer.

  For instance, if the geometry is in a column named `footprint`, the tag map is stored in
  a column named `details`, and the id is `building_id`, this can be defined as:

    ```elixir
    %{geometry: :footprint, id: :building_id, tags: :details}
    ```
  """
  @type columns_definition :: %{geometry: column_name, id: column_name, tags: column_name}

  @typedoc """
  Defines how to a vector tile layer shoudl be loaded from the database.

    * name: what the layer will be named in the resulting tile
    * source: the table to populate the layer from
    * prefix: the schema prefix for the table, or `nil` to use the default schema
    * columns: the columns to load from this table. See `t:columns_definition/0`
    * srid: the spatial reference ID to return the layer in (defaults to 4326, aka WGS 84)
    * compose_query_fn: an optional function that allows adding custom clauses to the resulting Ecto query
  """
  @type t :: %__MODULE__{
          name: String.t(),
          source: String.t(),
          prefix: String.t() | nil,
          columns: columns_definition,
          srid: integer,
          compose_query_fn: (Ecto.Query.t() -> Ecto.Query.t())
        }

  @doc false
  def identity_composer(query), do: query
end
