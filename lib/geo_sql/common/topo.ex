defmodule GeoSQL.Common.Topo do
  @moduledoc """
  Non-standard but commonly implement Topological functions which can be applied to a toplogy object.

  Topology functions which operate on geometries that are passed into them rather than a
  topology object are found in the `GeoSQL.Common` module.
  """

  @spec get_edge_by_point(
          object :: String.t(),
          topology_name :: String.t(),
          point :: GeoSQL.geometry_input(),
          tolerance :: number
        ) ::
          GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_edge_by_point(object, topology_name, point, tolerance) do
    quote do
      fragment(
        "?.GetEdgeByPoint(?,?,?)",
        unquote(object),
        unquote(topology_name),
        unquote(point),
        unquote(tolerance)
      )
    end
  end

  @spec get_face_by_point(
          object :: String.t(),
          topology_name :: String.t(),
          point :: GeoSQL.geometry_input(),
          tolerance :: number
        ) ::
          GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_face_by_point(object, topology_name, point, tolerance) do
    quote do
      fragment(
        "?.GetFaceeByPoint(?,?,?)",
        unquote(object),
        unquote(topology_name),
        unquote(point),
        unquote(tolerance)
      )
    end
  end

  @spec get_face_edges(
          object :: String.t(),
          topology_name :: String.t(),
          face :: non_neg_integer()
        ) :: GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_face_edges(object, topology_name, face) do
    quote do
      fragment(
        "?.ST_GetFaceEdges(?,?)",
        unquote(object),
        unquote(topology_name),
        unquote(face)
      )
    end
  end

  @spec get_face_geometry(
          object :: String.t(),
          topology_name :: String.t(),
          face :: non_neg_integer()
        ) :: GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_face_geometry(object, topology_name, face) do
    quote do
      fragment(
        "?.ST_GetFaceGeometry(?,?)",
        unquote(object),
        unquote(topology_name),
        unquote(face)
      )
    end
  end

  @spec get_node_by_point(
          object :: String.t(),
          topology_name :: String.t(),
          point :: GeoSQL.geometry_input(),
          tolerance :: number
        ) ::
          GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_node_by_point(object, topology_name, point, tolerance) do
    quote do
      fragment(
        "?.GetNodeByPoint(?,?,?)",
        unquote(object),
        unquote(topology_name),
        unquote(point),
        unquote(tolerance)
      )
    end
  end
end
