defmodule GeoSQL.RepoUtils do
  @moduledoc false
  @default_adapter Ecto.Adapters.Postgres

  defmacro adapter(repo) do
    quote do
      if unquote(repo) == nil do
        unquote(@default_adapter)
      else
        Macro.expand(unquote(repo), __CALLER__).__adapter__()
      end
    end
  end

  # query_results can be:
  # [ ... ] -> one list entry
  # [ [],....] -> many lists
  # %{} -> one map emtry
  # [%{}, ...] -> many map emtries
  def decode(nil, _repo, _transformations), do: nil
  def decode([], _repo, _transformations), do: []

  def decode(query_results, repo, fields_to_decode) do
    case repo.__adapter__() do
      Ecto.Adapters.Postgres ->
        query_results

      Ecto.Adapters.SQLite3 ->
        decode_geometry(query_results, GeoSQL.SpatialLite.TypeExtension, fields_to_decode)
    end
  end

  defp decode_geometry(%{} = query_results, type_extension, fields_to_decode) do
    Enum.reduce(fields_to_decode, query_results, fn field, query_result ->
      encoded_field = Map.get(query_result, field)

      if encoded_field == nil do
        query_result
      else
        Map.put(query_result, field, type_extension.decode_geometry(encoded_field))
      end
    end)
  end

  defp decode_geometry([head | _] = query_results, type_extension, fields_to_decode)
       when is_list(head) or is_map(head) do
    Enum.map(query_results, fn query_result ->
      decode_geometry(query_result, type_extension, fields_to_decode)
    end)
  end

  defp decode_geometry(query_result, type_extension, fields_to_decode)
       when is_list(query_result) do
    query_result
    |> Enum.with_index(fn encoded_field, index ->
      if Enum.member?(fields_to_decode, index) do
        type_extension.decode_geometry(encoded_field)
      else
        encoded_field
      end
    end)
  end
end
