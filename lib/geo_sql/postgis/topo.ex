defmodule GeoSQL.PostGIS.Topo do
  @moduledoc """
  Topological functions implemented in PostGIS which can be applied to a toplogy object.

  Topology functions which operate on geometries that are passed into them rather than a
  topology object are found in the `GeoSQL.PostGIS` module.
  """

  @spec get_face_containing_point(
          object :: String.t(),
          topology_name :: String.t(),
          point :: GeoSQL.geometry_input()
        ) :: GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_face_containing_point(object, topology_name, point) do
    quote do
      fragment(
        "?.GetFaceeContainingPoint(?,?)",
        unquote(object),
        unquote(topology_name),
        unquote(point)
      )
    end
  end

  @spec get_node_edges(
          object :: String.t(),
          topology_name :: String.t(),
          node :: non_neg_integer()
        ) :: GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_node_edges(object, topology_name, node) do
    quote do
      fragment(
        "?.GetNodeEdges(?,?)",
        unquote(object),
        unquote(topology_name),
        unquote(node)
      )
    end
  end

  @spec get_ring_edges(
          object :: String.t(),
          topology_name :: String.t(),
          ring :: non_neg_integer()
        ) :: GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_ring_edges(object, topology_name, ring) do
    quote do
      fragment(
        "?.GetRingEdges(?,?)",
        unquote(object),
        unquote(topology_name),
        unquote(ring)
      )
    end
  end

  @spec get_ring_edges(
          object :: String.t(),
          topology_name :: String.t(),
          ring :: non_neg_integer(),
          max_edges :: non_neg_integer()
        ) :: GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_ring_edges(object, topology_name, ring, max_edges) do
    quote do
      fragment(
        "?.GetRingEdges(?,?,?)",
        unquote(object),
        unquote(topology_name),
        unquote(ring),
        unquote(max_edges)
      )
    end
  end

  @spec get_topology_id(object :: String.t(), topology_name :: String.t()) :: GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_topology_id(object, topology_name) do
    quote do
      fragment(
        "?.GetTopologyID(?)",
        unquote(object),
        unquote(topology_name)
      )
    end
  end

  @spec get_topology_id(object :: String.t(), topology_name :: String.t()) :: GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_topology_srid(object, topology_name) do
    quote do
      fragment(
        "?.GetTopologySRID(?)",
        unquote(object),
        unquote(topology_name)
      )
    end
  end

  @spec get_topology_name(object :: String.t(), topology_id :: number) :: GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_topology_name(object, topology_id) do
    quote do
      fragment(
        "?.GetTopologyName(?)",
        unquote(object),
        unquote(topology_id)
      )
    end
  end
end
