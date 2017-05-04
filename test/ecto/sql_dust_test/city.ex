defmodule Ecto.SqlDustTest.City do
  use Ecto.Schema

  schema "cities" do
    field :name, :string
    has_many :local_weather, Ecto.SqlDustTest.Weather
    belongs_to :country, Ecto.SqlDustTest.Country
  end
end
