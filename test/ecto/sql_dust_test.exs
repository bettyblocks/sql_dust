defmodule Test do
  defmodule Weather do
    use Ecto.Schema
    schema "weather" do
      belongs_to :city, Test.City
    end
  end

  defmodule City do
    use Ecto.Schema
    schema "cities" do
      has_many :local_weather, Test.Weather
      belongs_to :country, Test.Country
    end
  end

  defmodule Country do
    use Ecto.Schema
    schema "countries" do
      has_many :cities, Test.City
      # has_many :weather, through: [:cities, :local_weather] ???
    end
  end
end

defmodule Ecto.SqlDustTest do
  use ExUnit.Case
  doctest Ecto.SqlDust
  import Ecto.SqlDust

  test "generates simple SQL based on Ecto model schemas" do
    sql = Test.Weather
      |> to_sql

    assert sql == {"""
      SELECT "w".*
      FROM "weather" "w"
      """, []}
  end

  test "generates simple SQL based on Ecto model schemas (using from)" do
    sql = from(Test.Weather)
      |> to_sql

    assert sql == {"""
      SELECT "w".*
      FROM "weather" "w"
      """, []}
  end

  test "generates SQL based on Ecto model schemas" do
    sql = Test.City
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
    sql = Test.City
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
end
