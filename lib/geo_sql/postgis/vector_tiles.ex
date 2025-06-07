defmodule GeoSQL.PostGIS.VectorTiles do
  import Ecto.Query
  use GeoSQL.MM2
  require GeoSQL.PostGIS
  import GeoSQL.PostGIS.Operators
  alias GeoSQL.PostGIS

  @moduledoc """
    Non-standard tile generation functions found in PostGIS.

    These are often more optimized and/or specialized than their ST_* equivalents.
  """

  defmacro as_mvt(rows, options) do
    allowed = [:name, :extent, :geom_name, :feature_id_name]

    {param_string, params} =
      PostGIS.Utils.as_positional_params(options, allowed)

    template = "ST_AsMVT(? #{param_string})"

    quote do
      fragment(
        unquote(template),
        unquote(rows),
        unquote_splicing(params)
      )
    end
  end

  defmacro as_mvt_geom(geometry, bounds) do
    quote do: fragment("ST_AsMVTGeom(?, ?)", unquote(geometry), unquote(bounds))
  end

  defmacro as_mvt_geom(geometry, bounds, options) do
    allowed = [:extent, :buffer, :clip_geom]
    {param_string, params} = PostGIS.Utils.as_positional_params(options, allowed)
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

  defmacro as_mvt(rows) do
    quote do: fragment("ST_AsMVT(?)", unquote(rows))
  end

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

  # geom_query(z, x, y, "nodes", :geom, :node_id, :tags)
  @spec generate(
          repo :: Ecto.Repo.t(),
          zoom :: non_neg_integer(),
          x :: non_neg_integer(),
          y :: non_neg_integer(),
          layers :: [__MODULE__.Layer.t()],
          db_prefix :: String.t() | nil
        ) :: term
  def generate(repo, zoom, x, y, layers, db_prefix \\ nil)

  def generate(_repo, _zoom, _x, _y, [], _db_prefix), do: []

  def generate(repo, zoom, x, y, layers, db_prefix) do
    geometry = geom_query(zoom, x, y, layers)

    from(g in subquery(geometry, prefix: db_prefix),
      select: as_mvt(g, name: g.name)
    )
    |> repo.all()
  end

  @spec geom_query(
          z :: non_neg_integer(),
          x :: non_neg_integer(),
          y :: non_neg_integer(),
          layers :: [__MODULE__.Layer.t()]
        ) :: Ecto.Query.t()
  defp geom_query(z, x, y, layers) do
    Enum.reduce(layers, nil, fn %{columns: columns} = layer, union_query ->
      from(g in "nodes",
        where:
          bbox_intersects?(
            field(g, ^columns.geometry),
            MM2.transform(tile_envelope(^z, ^x, ^y), 4326)
          ),
        select: %{
          name: ^layer.name,
          geom:
            as_mvt_geom(
              field(g, ^columns.geometry),
              MM2.transform(tile_envelope(^z, ^x, ^y), 4326)
            ),
          id: field(g, ^columns.id),
          tags: field(g, ^columns.tags)
        }
      )
      |> maybe_union(union_query)
    end)
  end

  defp maybe_union(query, nil), do: query
  defp maybe_union(query, union_query), do: union_all(query, ^union_query)
end
