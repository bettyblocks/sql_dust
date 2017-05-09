defmodule TalkTest.SqlDust do
  import Ecto.SqlDust

  alias TalkTest.{Post,Comment}

  def example1(title) do
    Post
    |> where("published_at IS NULL")
    |> where(["title = LOWER(?)", title])
    |> to_structs(TestRepo)
  end

  def example2(post_id) do
    Comment
    |> where(["post.id = ?", post_id])
    |> to_structs(TestRepo)
  end

  def example3(vote_count) do
    Post
    |> select("title, GROUP_CONCAT(DISTINCT comments.commenter ORDER BY comments.commenter) AS commenters, SUM(comments.votes) AS votes")
    |> where(["votes >= ?", vote_count])
    |> group_by("id")
    |> to_maps(TestRepo)
  end

  def example4(criteria) do
    Post
    |> select("title, GROUP_CONCAT(DISTINCT tags.name ORDER BY tags.name) AS tagged")
    |> where(["tags.name LIKE ?", "%#{criteria}%"])
    |> group_by("id")
    |> to_maps(TestRepo)
  end

end
