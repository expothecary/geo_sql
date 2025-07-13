defmodule GeoSQL.QueryUtils.Test do
  use ExUnit.Case, async: true
  @moduletag :query_utils

  import Ecto.Query
  use GeoSQL.QueryUtils
  use GeoSQL.RepoUtils
  use GeoSQL.Common
  use GeoSQL.Test.Helper
  alias GeoSQL.Test.Schema.{GeoType}

  encoding_repos = [Ecto.Adapters.SQLite3]

  def encoded do
    <<0, 1, 230, 16, 0, 0, 0, 0, 0, 0, 0, 0, 62, 64, 0, 0, 0, 0, 0, 160, 86, 192, 0, 0, 0, 0, 0,
      0, 62, 64, 0, 0, 0, 0, 0, 160, 86, 192, 124, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 62, 64, 0, 0, 0,
      0, 0, 160, 86, 192, 254>>
  end

  def decoded, do: %Geometry.Point{coordinates: [30.0, -90.5], srid: 4326}

  for repo <- Helper.repos() do
    describe "cast to geometry (#{repo})" do
      test "creates a correct cast to geometry" do
        query =
          from(location in GeoType,
            select:
              Common.add_point(
                QueryUtils.cast_to_geometry(location.linestring, unquote(repo)),
                location.point
              )
          )

        {query_string, _args} = unquote(repo).to_sql(:all, query)

        pattern = ~r/.*ST_AddPoint\(CAST\(s0."linestring" AS geometry\).*/

        case RepoUtils.adapter_for(unquote(repo)) do
          Ecto.Adapters.Postgres ->
            assert(Regex.match?(pattern, query_string))

          Ecto.Adapters.SQLite3 ->
            refute(Regex.match?(pattern, query_string))
        end
      end
    end

    if Enum.member?(encoding_repos, RepoUtils.adapter_for(repo)) do
      describe "decode_geometry (#{repo})" do
        test "supports tuples" do
          assert QueryUtils.decode_geometry({"hello", encoded(), 1}, unquote(repo), [1]) ==
                   {"hello", decoded(), 1}

          assert QueryUtils.decode_geometry({encoded()}, unquote(repo), [0]) ==
                   {decoded()}

          assert QueryUtils.decode_geometry({encoded(), 1}, unquote(repo), [0]) ==
                   {decoded(), 1}

          assert QueryUtils.decode_geometry({1, encoded()}, unquote(repo), [1]) ==
                   {1, decoded()}
        end

        test "is resilient to misuse" do
          assert QueryUtils.decode_geometry({"nothing", 1, 2, 3}, unquote(repo), [0, 1, 2, 3]) ==
                   {"nothing", 1, 2, 3}

          assert QueryUtils.decode_geometry({"hello", encoded(), 1}, unquote(repo), [2]) ==
                   {"hello", encoded(), 1}

          assert QueryUtils.decode_geometry({"hello", encoded(), 1}, unquote(repo), [2]) ==
                   {"hello", encoded(), 1}
        end
      end
    end

    if not Enum.member?(encoding_repos, RepoUtils.adapter_for(repo)) do
      describe "decode_geometry (#{repo})" do
        test "decode_geometry is a no-oṗ" do
          query_result = {"hello", encoded(), 1}
          assert QueryUtils.decode_geometry(query_result, unquote(repo), [1]) == query_result
        end
      end
    end
  end
end
