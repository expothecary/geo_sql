defmodule GeoSQL.Test.PostGIS.Repo do
  use Ecto.Repo, otp_app: :geo_sql, adapter: Ecto.Adapters.Postgres

  def has_array_literals?, do: true
  def to_boolean(value), do: value
end

defmodule GeoSQL.Test.SpatiaLite.Repo do
  use Ecto.Repo, otp_app: :geo_sql, adapter: Ecto.Adapters.SQLite3

  def has_array_literals?, do: false
  def to_boolean(1), do: true
  def to_boolean(0), do: false
end

defmodule GeoSQL.Test.Geopackage.Repo do
  use Ecto.Repo, otp_app: :geo_sql, adapter: Ecto.Adapters.SQLite3

  def has_array_literals?, do: false
  def to_boolean(1), do: true
  def to_boolean(0), do: false
end

# For the migrations.
GeoSQL.init(GeoSQL.Test.PostGIS.Repo, json: Jason, decode_binary: :reference)
