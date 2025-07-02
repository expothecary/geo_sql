defmodule GeoSQL.Int4 do
  @moduledoc """
  A utility type to pin a number to a 32-bit integer, as required
  by some SQL functions.
  """
  use Ecto.Type
  def type, do: :int4
  def cast(value), do: {:ok, value}
  def load(value), do: {:ok, value}
  def dump(value), do: {:ok, value}
end
