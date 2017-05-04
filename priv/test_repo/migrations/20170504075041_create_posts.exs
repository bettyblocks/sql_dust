defmodule TestRepo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :body, :text
      add :published, :boolean
      add :published_at, :datetime

      timestamps()
    end
  end
end
