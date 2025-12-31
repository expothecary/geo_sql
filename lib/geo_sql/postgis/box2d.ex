defmodule GeoSQL.PostGIS.Box2D do
  @moduledoc """
  A PostGIS Box2D.
  """

  defstruct xmin: 0.0, ymin: 0.0, xmax: 0.0, ymax: 0.0

  @type t :: %__MODULE__{xmin: float, ymin: float, xmax: float, ymax: float}
end
