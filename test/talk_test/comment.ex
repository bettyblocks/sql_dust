defmodule TalkTest.Comment do
  use Ecto.Schema

  schema "comments" do
    field :commenter, :string
    field :title, :string
    field :votes, :integer
    belongs_to :post, TalkTest.Post
    timestamps()
  end
end
