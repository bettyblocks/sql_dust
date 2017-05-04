defmodule TestRepo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :commenter, :string
      add :title, :string
      add :votes, :integer
      add :post_id, references(:posts)

      timestamps()
    end
  end
end
