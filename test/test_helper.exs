ExUnit.start()

defmodule SqlDust.ExUnit.Case do
  use ExUnit.CaseTemplate

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
    :ok = Ecto.Adapters.SQL.Sandbox.mode(TestRepo, {:shared, self()})

    Ecto.Adapters.SQL.query!(TestRepo, "SET FOREIGN_KEY_CHECKS = 0", [])

    populate(Ecto.SqlDustTest.City, [
      %{name: "Amsterdam"},
      %{name: "New York"},
      %{name: "Barcelona"},
      %{name: "London"}
    ])

    populate(TalkTest.Post, [
      %{title: "Hi"},
      %{title: "Hello, Elixir!"},
      %{title: "Ola, Barcelona :)"}
    ])

    populate(TalkTest.Comment, [
      %{commenter: "Paul Engel", title: "Nice language", votes: 18, post_id: 2},
      %{commenter: "Darth Vader", title: "I like the lack of objects", votes: 29, post_id: 2},
      %{commenter: "Lionel", title: "Great soccer stadium", votes: 91, post_id: 3},
      %{commenter: "MJ", title: "Hihi!", votes: 9, post_id: 1}
    ])

    populate(TalkTest.Tag, [
      %{name: "elixir"},
      %{name: "conference"},
      %{name: "barcelona"},
      %{name: "language"}
    ])

    Ecto.Adapters.SQL.query!(TestRepo, "INSERT INTO posts_tags (post_id, tag_id) VALUES (2, 1)", [])
    Ecto.Adapters.SQL.query!(TestRepo, "INSERT INTO posts_tags (post_id, tag_id) VALUES (2, 4)", [])
    Ecto.Adapters.SQL.query!(TestRepo, "INSERT INTO posts_tags (post_id, tag_id) VALUES (3, 1)", [])
    Ecto.Adapters.SQL.query!(TestRepo, "INSERT INTO posts_tags (post_id, tag_id) VALUES (3, 2)", [])
    Ecto.Adapters.SQL.query!(TestRepo, "INSERT INTO posts_tags (post_id, tag_id) VALUES (3, 3)", [])

    Ecto.Adapters.SQL.query!(TestRepo, "SET FOREIGN_KEY_CHECKS = 1", [])

    :ok
  end

  defp populate(schema, maps) do
    table = schema.__schema__(:source)
    fields = schema.__schema__(:fields)
    columns = fields |> Enum.map(&Atom.to_string/1) |> Enum.join(", ")

    Ecto.Adapters.SQL.query!(TestRepo, "TRUNCATE #{table}", [])
    Enum.each(maps, fn(map) ->
      values =
        fields
        |> Enum.map(fn(field) ->
          value = Map.get(map, field)
          case field do
            :inserted_at -> value || "NOW()"
            :updated_at -> value || "NOW()"
            _ -> if (value), do: inspect(value), else: "NULL"
          end
        end)
        |> Enum.join(", ")

      sql = "INSERT INTO #{table} (#{columns}) VALUES (#{values})"
      Ecto.Adapters.SQL.query!(TestRepo, sql, [])
    end)
  end
end

{:ok, _pid} = TestRepo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(TestRepo, {:shared, self()})
