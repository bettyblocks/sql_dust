defmodule Ecto.SqlDustTest.Weather do
  use Ecto.Schema

  schema "weather" do
    belongs_to :city, Ecto.SqlDustTest.City
  end
end
