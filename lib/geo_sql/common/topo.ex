defmodule GeoSQL.Common.Topo do
  @moduledoc """
  Non-standard but commonly implement Topological functions which can be applied to a toplogy object.

  Topology functions which operate on geometries that are passed into them rather than a
  topology object are found in the `GeoSQL.Common` module.
  """

  @spec get_edge_by_point(
          topology :: String.t(),
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
          topology :: String.t(),
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
end
