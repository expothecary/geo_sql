defmodule GeoSQL.Int4 do
  @moduledoc """
  A utility type to pin a number to a 32-bit integer, as required
  by some SQL functions. Can be used in Ecto schemas as `GeoSQL.Int4`
  or dynamically in queries such as `type(^layer.srid, GeoSQL.Int4)`.
  """

  use Ecto.Type

  @doc false
  def type, do: :int4

  @doc false
  def cast(value), do: {:ok, value}

  @doc false
  def load(value), do: {:ok, value}

  @doc false
  def dump(value), do: {:ok, value}

  @doc false
  def embed_as(_), do: :self

  @doc false
  def equal?(left, right), do: left == right
end
