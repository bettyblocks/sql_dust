defmodule TalkTest.Tag do
  use Ecto.Schema

  schema "tags" do
    field :name, :string
    many_to_many :posts, TalkTest.Post, join_through: "posts_tags"
  end
end
