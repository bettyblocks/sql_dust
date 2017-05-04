defmodule TestRepo.Migrations.CreateCities do
  use Ecto.Migration

  def change do
    create table(:cities) do
      add :name, :string
      add :country_id, :integer
    end
  end
end
