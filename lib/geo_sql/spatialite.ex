defmodule GeoSQL.SpatiaLite do
  @moduledoc """
    Non-standard GIS functions found in Spatialite.
  """

  defmacro __using__(_) do
    quote do
      require GeoSQL.SpatiaLite
      alias GeoSQL.SpatiaLite
    end
  end

  @doc group: "Geopackage"
  defmacro as_gpb(geometry) do
    quote do: fragment("AsGPB(?)", unquote(geometry))
  end

  @doc group: "Geopackage"
  defmacro geom_from_gpb(gpb_blob) do
    quote do: fragment("GeomFromGPB(?)", unquote(gpb_blob))
  end

  @doc group: "Geopackage"
  defmacro is_valid_gpb(gpb_blob) do
    quote do: fragment("IsValidGPB(?)", unquote(gpb_blob))
  end
end
