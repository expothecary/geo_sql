defmodule GeoSQL.PostGIS.Topo do
  @moduledoc """
  Topological functions implemented in PostGIS which can be applied to a toplogy object.

  Topology functions which operate on geometries that are passed into them rather than a
  topology object are found in the `GeoSQL.PostGIS` module.
  """

  @spec get_face_containing_point(
          topology :: String.t(),
          topology_name :: String.t(),
          point :: GeoSQL.geometry_input()
        ) ::
          GeoSQL.fragment()
  @doc group: "Accessors"
  defmacro get_face_containing_point(object, topology_name, point) do
    quote do
      fragment(
        "?.GetFaceeContainingPoint(?,?,?)",
        unquote(object),
        unquote(topology_name),
        unquote(point)
      )
    end
  end
end
