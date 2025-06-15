defmodule GeoSQL.Common.Topo do
  @moduledoc """
  Non-standard but commonly implement Topological functions which can be applied to a toplogy object.

  Topology functions which operate on geometries that are passed into them rather than a
  topology object are found in the `GeoSQL.Common` module.
  """

  alias GeoSQL.RepoUtils

  @spec add_line_string(
          object :: String.t(),
          topology_name :: String.t(),
          line :: GeoSQL.geometry_input(),
          tolerance :: number
        ) :: GeoSQL.fragment()
  @doc group: "Processors"
  defmacro add_line_string(object, topology_name, line, tolerance) do
    fragment(
      "?.TopoGeo_AddLineString(?,?,?)",
      unquote(object),
      unquote(topology_name),
      unquote(line),
      unquote(tolerance)
    )
  end

  @spec add_point(
          object :: String.t(),
          topology_name :: String.t(),
          point :: GeoSQL.geometry_input(),
          tolerance :: number
        ) :: GeoSQL.fragment()
  @doc group: "Processors"
  defmacro add_node(object, topology_name, point, tolerance) do
    fragment(
      "?.TopoGeo_AddPoint(?,?,?)",
      unquote(object),
      unquote(topology_name),
      unquote(point),
      unquote(tolerance)
    )
  end

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

  @spec polygonize(
          object :: String.t(),
          topology_name :: String.t(),
          repo :: Ecto.Repo.t() | nil
        ) :: GeoSQL.fragment()
  @doc group: "Processors"
  defmacro polygonize(
             object,
             topology_name,
             repo \\ nil
           ) do
    case RepoUtils.adapter(repo) do
      Ecto.Adapters.Postgres ->
        fragment(
          "?.Polygonize(?)",
          unquote(object),
          unquote(topology_name)
        )

      Ecto.Adapters.SQLite3 ->
        fragment(
          "?.TopoGeo_Polygonize(?,?)",
          unquote(object),
          unquote(topology_name)
        )
    end
  end
end
