defmodule GeoSQL.QueryUtils.Test do
  use ExUnit.Case, async: true
  @moduletag :query_utils

  import Ecto.Query
  use GeoSQL.QueryUtils
  use GeoSQL.Common
  use GeoSQL.Test.Helper
  alias GeoSQL.Test.Schema.{GeoType}

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

        case GeoSQL.RepoUtils.adapter_for(unquote(repo)) do
          Ecto.Adapters.Postgres ->
            assert(Regex.match?(pattern, query_string))

          Ecto.Adapters.SQLite3 ->
            refute(Regex.match?(pattern, query_string))
        end
      end
    end
  end
end
