defmodule Int4 do
  use Ecto.Type
  def type, do: :int4
  def cast(value), do: {:ok, value}
  def load(value), do: {:ok, value}
  def dump(value), do: {:ok, value}
end
