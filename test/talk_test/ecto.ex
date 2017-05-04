defmodule TalkTest.Ecto do
  import Ecto.Query

  alias TalkTest.{Post,Comment}

  def example1(title) do
    # TestRepo.all(
    #   from p in Post,
    #     where: is_nil(p.published_at) and
    #            fragment("lower(?)", p.title) == ^title
    # )

    Post
    |> where([p], is_nil(p.published_at))
    |> where([p], fragment("LOWER(?)", p.title) == ^title)
    |> TestRepo.all()
  end

  def example2(post_id) do
    Comment
    |> select([c, _], c)
    |> join(:left, [c], p in assoc(c, :post))
    |> where([_, p], p.id == ^post_id)
    |> TestRepo.all
  end

  def example3(vote_count) do
    TestRepo.all(
      from post in Post,
        join: comments in assoc(post, :comments),
        select: %{
          title: post.title,
          commenters: fragment("GROUP_CONCAT(DISTINCT ?)", comments.commenter),
          votes: fragment("SUM(?) AS votes", comments.votes)
        },
        having: fragment("votes >= ?", ^vote_count),
        group_by: post.id
    )
    |> Enum.map(fn(map) ->
      map
      |> Enum.map(fn({k, v}) -> {Atom.to_string(k), v} end)
      |> Enum.into(%{})
    end)
  end

  def example4(criteria) do
    criteria = "%#{criteria}%"

    TestRepo.all(
      from post in Post,
        join: tags in assoc(post, :tags),
        select: %{
          title: post.title,
          tagged: fragment("GROUP_CONCAT(DISTINCT ?)", tags.name)
        },
        where: fragment("? LIKE ?", tags.name, ^criteria),
        group_by: post.id
    )
    |> Enum.map(fn(map) ->
      map
      |> Enum.map(fn({k, v}) -> {Atom.to_string(k), v} end)
      |> Enum.into(%{})
    end)
  end

end
