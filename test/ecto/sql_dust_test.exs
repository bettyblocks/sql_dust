defmodule Ecto.SqlDustTest do
  use SqlDust.ExUnit.Case
  doctest Ecto.SqlDust
  import Ecto.SqlDust

  alias Ecto.SqlDustTest.{City, Weather}

  test "generates simple SQL based on Ecto model schemas" do
    sql = Weather
      |> to_sql

    assert sql == {"""
      SELECT "w".*
      FROM "weather" "w"
      """, []}
  end

  test "generates simple SQL based on Ecto model schemas (using from)" do
    sql = from(Weather)
      |> to_sql

    assert sql == {"""
      SELECT "w".*
      FROM "weather" "w"
      """, []}
  end

  test "generates SQL based on Ecto model schemas" do
    sql = City
      |> select("id, name, country.name, local_weather.temp_lo, local_weather.temp_hi")
      |> where("local_weather.wdate = '2015-09-12'")
      |> to_sql

    assert sql == {"""
      SELECT
        "c"."id",
        "c"."name",
        "country"."name",
        "local_weather"."temp_lo",
        "local_weather"."temp_hi"
      FROM "cities" "c"
      LEFT JOIN "countries" "country" ON "country"."id" = "c"."country_id"
      LEFT JOIN "weather" "local_weather" ON "local_weather"."city_id" = "c"."id"
      WHERE ("local_weather"."wdate" = '2015-09-12')
      """, []}
  end

  test "support generating SQL based on Ecto model schemas for MySQL" do
    sql = City
      |> select("id, name, country.name, local_weather.temp_lo, local_weather.temp_hi")
      |> where(["local_weather.wdate = ?", "2015-09-12"])
      |> adapter(:mysql)
      |> to_sql

    assert sql == {"""
      SELECT
        `c`.`id`,
        `c`.`name`,
        `country`.`name`,
        `local_weather`.`temp_lo`,
        `local_weather`.`temp_hi`
      FROM `cities` `c`
      LEFT JOIN `countries` `country` ON `country`.`id` = `c`.`country_id`
      LEFT JOIN `weather` `local_weather` ON `local_weather`.`city_id` = `c`.`id`
      WHERE (`local_weather`.`wdate` = ?)
      """, ["2015-09-12"]}
  end

  describe "querying data" do
    test ".to_lists()" do
      assert [
        [1, "Amsterdam", nil],
        [2, "New York", nil],
        [3, "Barcelona", nil],
        [4, "London", nil]
      ] == City |> to_lists(TestRepo)

      assert [
        "New York",
        "London",
        "Barcelona",
        "Amsterdam"
      ] == City |> select(:name) |> order_by("name DESC") |> to_lists(TestRepo)
    end

    test ".to_maps()" do
      assert [
        %{"id" => 1, "name" => "Amsterdam", "country_id" => nil},
        %{"id" => 2, "name" => "New York", "country_id" => nil},
        %{"id" => 3, "name" => "Barcelona", "country_id" => nil},
        %{"id" => 4, "name" => "London", "country_id" => nil}
      ] == City |> to_maps(TestRepo)

      assert [
        %{"name" => "New York"},
        %{"name" => "London"},
        %{"name" => "Barcelona"},
        %{"name" => "Amsterdam"}
      ] == City |> select(:name) |> order_by("name DESC") |> to_maps(TestRepo)
    end

    test ".to_structs()" do
      assert [
        %City{id: 1, name: "Amsterdam"},
        %City{id: 2, name: "New York"},
        %City{id: 3, name: "Barcelona"},
        %City{id: 4, name: "London"}
      ] = City |> to_structs(TestRepo)

      assert [
        %City{id: 2, name: "New York"},
        %City{id: 4, name: "London"},
        %City{id: 3, name: "Barcelona"},
        %City{id: 1, name: "Amsterdam"}
      ] = City |> order_by("name DESC") |> to_structs(TestRepo)
    end
  end

end
