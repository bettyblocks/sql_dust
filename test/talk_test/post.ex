defmodule TalkTest.Post do
  use Ecto.Schema

  schema "posts" do
    field :title, :string
    field :body, :string
    field :published, :boolean
    field :published_at, Ecto.DateTime
    timestamps()
    many_to_many :tags, TalkTest.Tag, join_through: "posts_tags"
    has_many :comments, TalkTest.Comment
  end
end
