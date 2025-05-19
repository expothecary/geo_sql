defmodule GeoSQL.MM3.Topo do
  @moduledoc """
  SQL/MM3 Topological functions prefixed with `ST_` in the standard which can be used in ecto queries.

  This may require additional dependencies and configuration in the GIS store. For example,
  PostGIS requires the SFCGAL backend for some of these functions.
  """

  defmacro add_edge_mod_face(object, topology, nodeA, nodeB, curve) do
    quote do
      fragment(
        "?.ST_AddEdgeModFace(?, ?, ?, ?)",
        unquote(object),
        unquote(topology),
        unquote(nodeA),
        unquote(nodeB),
        unquote(curve)
      )
    end
  end

  defmacro add_edge_new_faces(object, topology, nodeA, nodeB, curve) do
    quote do
      fragment(
        "?.ST_AddEdgeNewFaces(?, ?, ?, ?)",
        unquote(object),
        unquote(topology),
        unquote(nodeA),
        unquote(nodeB),
        unquote(curve)
      )
    end
  end

  defmacro add_iso_edge(object, topology, nodeA, nodeB, linestring) do
    quote do
      fragment(
        "?.ST_AddIsoEdge(?, ?, ?, ?)",
        unquote(object),
        unquote(topology),
        unquote(nodeA),
        unquote(nodeB),
        unquote(linestring)
      )
    end
  end

  defmacro add_iso_node(object, topology, face, point) do
    quote do
      fragment(
        "?.ST_AddIsoNode(?, ?, ?)",
        unquote(object),
        unquote(topology),
        unquote(face),
        unquote(point)
      )
    end
  end

  defmacro change_edge_gome(object, topology, edge, curve) do
    quote do
      fragment(
        "?.ST_ChangeEdgeGeom(?, ?, ?)",
        unquote(object),
        unquote(topology),
        unquote(edge),
        unquote(curve)
      )
    end
  end

  defmacro create_topo_geo(object, topo) do
    quote do: fragment("?.ST_CreateTopoGeo(?)", unquote(object), unquote(topo))
  end

  defmacro get_face_edges(object, topology, face) do
    quote do
      fragment(
        "?.ST_GetFaceEdges(?, ?)",
        unquote(object),
        unquote(topology),
        unquote(face)
      )
    end
  end

  defmacro get_face_geometry(object, topology, face) do
    quote do
      fragment(
        "?.ST_GetFaceGeometry(?, ?, ?)",
        unquote(object),
        unquote(topology),
        unquote(face)
      )
    end
  end

  defmacro init_topo_geo(object, topology_schema_name) do
    quote do: fragment("?.ST_InitTopoGeo(?)", unquote(object), unquote(topology_schema_name))
  end

  defmacro mod_edge_heal(object, topology, edgeA, edgeB) do
    quote do
      fragment(
        "?.ST_ModEdgeHeal(?, ?, ?)",
        unquote(object),
        unquote(topology),
        unquote(edgeA),
        unquote(edgeB)
      )
    end
  end

  defmacro mod_edge_split(object, topology, edge, point) do
    quote do
      fragment(
        "?.ST_ModEdgeSplit(?, ?, ?)",
        unquote(object),
        unquote(topology),
        unquote(edge),
        unquote(point)
      )
    end
  end

  defmacro move_iso_node(object, topology, node, point) do
    quote do
      fragment(
        "?.ST_MoveIsoNode(?, ?, ?, ?)",
        unquote(object),
        unquote(topology),
        unquote(node),
        unquote(point)
      )
    end
  end

  defmacro new_edge_heal(object, topology, edgeA, edgeB) do
    quote do
      fragment(
        "?.ST_NewEdgeHeal(?, ?, ?)",
        unquote(object),
        unquote(topology),
        unquote(edgeA),
        unquote(edgeB)
      )
    end
  end

  defmacro new_edge_split(object, topology, edge, point) do
    quote do
      fragment(
        "?.ST_NewEdgesSplit(?, ?, ?)",
        unquote(object),
        unquote(topology),
        unquote(edge),
        unquote(point)
      )
    end
  end

  defmacro remove_iso_edge(object, topology, edge) do
    quote do: fragment("?.ST_RemoveIsoEdge(?)", unquote(object), unquote(topology), unquote(edge))
  end

  defmacro remove_iso_node(object, topology, node) do
    quote do: fragment("?.ST_RemoveIsoNode(?)", unquote(object), unquote(topology), unquote(node))
  end

  defmacro rem_edge_mod_face(object, topology, edge) do
    quote do
      fragment("?.ST_RemEdgeModFace(?)", unquote(object), unquote(topology), unquote(edge))
    end
  end

  defmacro rem_edge_new_face(object, topology, edge) do
    quote do
      fragment(
        "?.ST_RemEdgeNewFace(?, ?)",
        unquote(object),
        unquote(topology),
        unquote(edge)
      )
    end
  end
end
