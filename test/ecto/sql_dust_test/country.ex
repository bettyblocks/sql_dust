defmodule Ecto.SqlDustTest.Country do
  use Ecto.Schema

  schema "countries" do
    has_many :cities, Ecto.SqlDustTest.City
    # has_many :weather, through: [:cities, :local_weather] ???
  end
end
