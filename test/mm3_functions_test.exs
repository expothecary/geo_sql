defmodule GeoSQL.MM3Functions.Test do
  use ExUnit.Case, async: true
  import Ecto.Query
  use GeoSQL.MM3
  use GeoSQL.Test.PostGIS.Helper

  alias GeoSQL.Test.Schema.{LocationMulti, Geographies}

  describe "MM3 Queries" do
    test "order by distance" do
      geom1 = %Geo.Point{coordinates: {30, -90}, srid: 4326}
      geom2 = %Geo.Point{coordinates: {30, -91}, srid: 4326}
      geom3 = %Geo.Point{coordinates: {60, -91}, srid: 4326}

      PostGISRepo.insert(%Geographies{name: "there", geom: geom2})
      PostGISRepo.insert(%Geographies{name: "here", geom: geom1})
      PostGISRepo.insert(%Geographies{name: "way over there", geom: geom3})

      query =
        from(
          location in Geographies,
          limit: 5,
          select: location,
          order_by: MM3.ThreeD.distance(location.geom, ^geom1)
        )

      assert ["here", "there", "way over there"] ==
               PostGISRepo.all(query)
               |> Enum.map(fn x -> x.name end)
    end
  end

  describe "is_empty/1" do
    test "returns true for an empty geometry" do
      empty_point = %Geo.Point{coordinates: nil, srid: 4326}

      PostGISRepo.insert(%LocationMulti{name: "empty_point", geom: empty_point})

      query =
        from(l in LocationMulti,
          where: l.name == "empty_point",
          select: MM3.is_empty(l.geom)
        )

      result = PostGISRepo.one(query)

      assert result == true
    end

    test "returns false for a non-empty geometry" do
      point = %Geo.Point{coordinates: {0, 0}, srid: 4326}
      PostGISRepo.insert(%LocationMulti{name: "non_empty", geom: point})

      query =
        from(l in LocationMulti,
          where: l.name == "non_empty",
          select: MM3.is_empty(l.geom)
        )

      result = PostGISRepo.one(query)
      assert result == false
    end
  end
end
