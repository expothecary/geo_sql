defmodule GeoSQL.PostGIS.VectorTiles do
  import Ecto.Query
  use GeoSQL.MM2
  require GeoSQL.PostGIS
  require GeoSQL.PostGIS.Operators
  alias GeoSQL.PostGIS
  alias GeoSQL.QueryUtils

  @moduledoc """
  In addition to support for functions related to Mapbox vector tiles, this module also
  provides support for generating complete tiles via `generate/6`.

  The `generate/6` function takes a list of `GeoSQL.PostGIS.VectorTiles.Layer` structs along
  with the tile coordinates and an `Ecto.Repo`:

    ```elixir
      use GeoSQL.PostGIS

      def tile(zoom, x, y) do
        layers = [
          %PostGIS.VectorTiles.Layer{
            name: "pois",
            source: "nodes",
            columns: %{geometry: :geom, id: :node_id, tags: :tags}
          },
          %PostGIS.VectorTiles.Layer{
            name: "buildings",
            source: "buildings",
            columns: %{geometry: :footprint, id: :id, tags: :tags}
          }
        ]


        PostGIS.VectorTiles.generate(MyApp.Repo, zoom, x, y, layers)
      end
    ```

  The resulting data can be loaded directly into map renderers such as `MapLibre` or `OpenLayers`
  with the `MVT` vector tile layer format.

  Database prefixes ("schemas" in PostgreSQL) are also supported both on the whole tile query
  as well as per-layer.

  For non-trivial tables, ensure that a `GIST` index exists on the geometry columns used.
  """

  @doc group: "SQL Functions"
  defmacro as_mvt(rows) do
    quote do: fragment("ST_AsMVT(?)", unquote(rows))
  end

  @doc group: "SQL Functions"
  defmacro as_mvt(rows, name) do
    quote do
      fragment("ST_AsMVT(?,?)", unquote(rows), unquote(name))
    end
  end

  @doc group: "SQL Functions"
  defmacro as_mvt(rows, name, extent) do
    quote do
      fragment("ST_AsMVT(?,?,?)", unquote(rows), unquote(name), unquote(extent))
    end
  end

  @doc group: "SQL Functions"
  defmacro as_mvt(rows, name, extent, geom_name) do
    quote do
      fragment(
        "ST_AsMVT(?,?,?,?)",
        unquote(rows),
        unquote(name),
        unquote(extent),
        unquote(geom_name)
      )
    end
  end

  @doc group: "SQL Functions"
  defmacro as_mvt(rows, name, extent, geom_name, feature_id_name) do
    quote do
      fragment(
        "ST_AsMVT(?,?,?,?,?)",
        unquote(rows),
        unquote(name),
        unquote(extent),
        unquote(geom_name),
        unquote(feature_id_name)
      )
    end
  end

  @doc group: "SQL Functions"
  defmacro as_mvt_geom(geometry, bounds) do
    quote do: fragment("ST_AsMVTGeom(?, ?)", unquote(geometry), unquote(bounds))
  end

  @doc group: "SQL Functions"
  defmacro as_mvt_geom(geometry, bounds, options) do
    allowed = [:extent, :buffer, :clip_geom]
    {param_string, params} = QueryUtils.as_positional_params(options, allowed)
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

  @doc group: "SQL Functions"
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

  @doc group: "SQL Functions"
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

  @spec generate(
          repo :: Ecto.Repo.t(),
          zoom :: non_neg_integer(),
          x :: non_neg_integer(),
          y :: non_neg_integer(),
          layers :: [__MODULE__.Layer.t()],
          db_prefix :: String.t() | nil
        ) :: term
  @doc group: "Tile Generation"
  def generate(repo, zoom, x, y, layers, db_prefix \\ nil)

  def generate(_repo, _zoom, _x, _y, [], _db_prefix), do: []

  def generate(repo, zoom, x, y, layers, db_prefix) do
    geometry = geom_query(zoom, x, y, layers)

    from(g in subquery(geometry, prefix: db_prefix),
      select: as_mvt(g, g.name)
    )
    |> repo.one()
  end

  @spec geom_query(
          z :: non_neg_integer(),
          x :: non_neg_integer(),
          y :: non_neg_integer(),
          layers :: [__MODULE__.Layer.t()]
        ) :: Ecto.Query.t()
  defp geom_query(z, x, y, layers) do
    Enum.reduce(layers, nil, fn %{columns: columns} = layer, union_query ->
      from(g in layer.source,
        prefix: ^layer.prefix,
        where:
          PostGIS.Operators.bbox_intersects?(
            field(g, ^columns.geometry),
            MM2.transform(tile_envelope(^z, ^x, ^y), type(^layer.srid, Int4))
          ),
        select: %{
          name: ^layer.name,
          geom:
            as_mvt_geom(
              field(g, ^columns.geometry),
              MM2.transform(
                tile_envelope(^z, ^x, ^y),
                type(^layer.srid, Int4)
              )
            ),
          id: field(g, ^columns.id),
          tags: field(g, ^columns.tags)
        }
      )
      |> layer.compose_query_fn.()
      |> maybe_union(union_query)
    end)
  end

  defp maybe_union(query, nil), do: query
  defp maybe_union(query, union_query), do: union_all(query, ^union_query)
end
