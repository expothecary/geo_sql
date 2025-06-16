defmodule GeoSQL.MM2Functions.Test do
  use ExUnit.Case, async: true
  import Ecto.Query
  use GeoSQL.MM2
  use GeoSQL.Test.PostGIS.Helper
  alias GeoSQL.Test.PostGIS.Helper

  alias GeoSQL.Test.Schema.Location

  describe "MM2 Queries" do
    test "query area" do
      geom = Geo.WKB.decode!(Helper.multipoint_wkb())

      PostGISRepo.insert(%Location{name: "hello", geom: geom})

      query = from(location in Location, limit: 5, select: MM2.area(location.geom))
      results = PostGISRepo.all(query)

      assert is_number(hd(results))
    end

    test "query transform" do
      geom = Geo.WKB.decode!(Helper.multipoint_wkb())

      PostGISRepo.insert(%Location{name: "hello", geom: geom})

      query = from(location in Location, limit: 1, select: MM2.transform(location.geom, 3452))
      results = PostGISRepo.one(query)

      assert results.srid == 3452
    end

    test "query distance" do
      geom = Geo.WKB.decode!(Helper.multipoint_wkb())

      PostGISRepo.insert(%Location{name: "hello", geom: geom})

      query = from(location in Location, limit: 5, select: MM2.distance(location.geom, ^geom))
      results = PostGISRepo.one(query)

      assert results == 0
    end

    test "example" do
      geom = Geo.WKB.decode!(Helper.multipoint_wkb())
      PostGISRepo.insert(%Location{name: "hello", geom: geom})

      defmodule Example do
        import Ecto.Query
        require GeoSQL.MM2
        alias GeoSQL.MM2

        def example_query(geom) do
          from(location in Location, select: MM2.distance(location.geom, ^geom))
        end
      end

      query = Example.example_query(geom)
      results = PostGISRepo.one(query)
      assert results == 0
    end
  end
end
