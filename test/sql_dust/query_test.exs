defmodule SqlDust.QueryTest do
  use ExUnit.Case
  doctest SqlDust.Query

  test "select returns SqlDust.QueryDust containing :select option (passing a string)" do
    query_dust = SqlDust.Query.select("id")

    assert query_dust == %SqlDust.QueryDust{
      select: ["id"]
    }
  end

  test "select returns SqlDust.QueryDust containing :select option (passing a list)" do
    query_dust = SqlDust.Query.select(["id"])

    assert query_dust == %SqlDust.QueryDust{
      select: ["id"]
    }
  end

  test "select appends an argument to existing :select option (passing a string)" do
    query_dust = SqlDust.Query.select("id")
      |> SqlDust.Query.select("name")

    assert query_dust == %SqlDust.QueryDust{
      select: ["id", "name"]
    }
  end

  test "select appends an argument to existing :select option (passing a list)" do
    query_dust = SqlDust.Query.select("id")
      |> SqlDust.Query.select(~w(name))

    assert query_dust == %SqlDust.QueryDust{
      select: ["id", "name"]
    }
  end

  test "from returns SqlDust.QueryDust containing :from option" do
    query_dust = SqlDust.Query.from("users")

    assert query_dust == %SqlDust.QueryDust{
      from: "users"
    }
  end

  test "from sets :from option of passed SqlDust.QueryDust" do
    query_dust = SqlDust.Query.select("id")
      |> SqlDust.Query.from("users")

    assert query_dust == %SqlDust.QueryDust{
      select: ["id"],
      from: "users"
    }
  end

  test "where returns SqlDust.QueryDust containing :where option (passing a string)" do
    query_dust = SqlDust.Query.where("company.name LIKE '%Engel%'")

    assert query_dust == %SqlDust.QueryDust{
      where: ["company.name LIKE '%Engel%'"]
    }
  end

  test "where returns SqlDust.QueryDust containing :where option (passing a list)" do
    query_dust = SqlDust.Query.where(["company.name LIKE '%Engel%'"])

    assert query_dust == %SqlDust.QueryDust{
      where: ["company.name LIKE '%Engel%'"]
    }
  end

  test "where appends an argument to existing :where option (passing a string)" do
    query_dust = SqlDust.Query.where("company.name LIKE '%Engel%'")
      |> SqlDust.Query.where("category_id = 1")

    assert query_dust == %SqlDust.QueryDust{
      where: ["company.name LIKE '%Engel%'", "category_id = 1"]
    }
  end

  test "where appends an argument to existing :where option (passing a list)" do
    query_dust = SqlDust.Query.where("company.name LIKE '%Engel%'")
      |> SqlDust.Query.where(["category_id = 1"])

    assert query_dust == %SqlDust.QueryDust{
      where: ["company.name LIKE '%Engel%'", "category_id = 1"]
    }
  end

  test "group_by returns SqlDust.QueryDust containing :group_by option (passing a string)" do
    query_dust = SqlDust.Query.group_by("company_id")

    assert query_dust == %SqlDust.QueryDust{
      group_by: ["company_id"]
    }
  end

  test "group_by returns SqlDust.QueryDust containing :group_by option (passing a list)" do
    query_dust = SqlDust.Query.group_by(["company_id"])

    assert query_dust == %SqlDust.QueryDust{
      group_by: ["company_id"]
    }
  end

  test "group_by appends an argument to existing :group_by option (passing a string)" do
    query_dust = SqlDust.Query.group_by("company_id")
      |> SqlDust.Query.group_by("category_id")

    assert query_dust == %SqlDust.QueryDust{
      group_by: ["company_id", "category_id"]
    }
  end

  test "group_by appends an argument to existing :group_by option (passing a list)" do
    query_dust = SqlDust.Query.group_by("company_id")
      |> SqlDust.Query.group_by(~w(category_id))

    assert query_dust == %SqlDust.QueryDust{
      group_by: ["company_id", "category_id"]
    }
  end

  test "order_by returns SqlDust.QueryDust containing :order_by option (passing a string)" do
    query_dust = SqlDust.Query.order_by("company_id")

    assert query_dust == %SqlDust.QueryDust{
      order_by: ["company_id"]
    }
  end

  test "order_by returns SqlDust.QueryDust containing :order_by option (passing a list)" do
    query_dust = SqlDust.Query.order_by(["company_id"])

    assert query_dust == %SqlDust.QueryDust{
      order_by: ["company_id"]
    }
  end

  test "order_by appends an argument to existing :order_by option (passing a string)" do
    query_dust = SqlDust.Query.order_by("company_id")
      |> SqlDust.Query.order_by("category_id")

    assert query_dust == %SqlDust.QueryDust{
      order_by: ["company_id", "category_id"]
    }
  end

  test "order_by appends an argument to existing :order_by option (passing a list)" do
    query_dust = SqlDust.Query.order_by("company_id")
      |> SqlDust.Query.order_by(~w(category_id))

    assert query_dust == %SqlDust.QueryDust{
      order_by: ["company_id", "category_id"]
    }
  end

  test "limit returns SqlDust.QueryDust containing :limit option" do
    query_dust = SqlDust.Query.limit(10)

    assert query_dust == %SqlDust.QueryDust{
      limit: 10
    }
  end

  test "limit sets :limit option of passed SqlDust.QueryDust" do
    query_dust = SqlDust.Query.select("id")
      |> SqlDust.Query.limit(10)

    assert query_dust == %SqlDust.QueryDust{
      select: ["id"],
      limit: 10
    }
  end

  test "limit overwrites :limit option within passed SqlDust.QueryDust" do
    query_dust = SqlDust.Query.select("id")
      |> SqlDust.Query.limit(10)
      |> SqlDust.Query.limit(100)

    assert query_dust == %SqlDust.QueryDust{
      select: ["id"],
      limit: 100
    }
  end

  test "schema returns SqlDust.QueryDust containing :schema option" do
    query_dust = SqlDust.Query.schema(%{
      "users": %{
        "skills": %{
          macro: :has_and_belongs_to_many
        }
      }
    })

    assert query_dust == %SqlDust.QueryDust{
      schema: %{
        users: %{
          skills: %{
            macro: :has_and_belongs_to_many
          }
        }
      }
    }
  end

  test "schema merges argument to existing :schema option" do
    query_dust = SqlDust.Query.schema(
        %{
          "users": %{
            "skills": %{
              macro: :has_and_belongs_to_many
            }
          }
        }
      )
      |> SqlDust.Query.schema(
        %{
          "users": %{
            "skills": %{
              "primary_key": "identifier"
            }
          },
          "relations": %{
            table_name: "users"
          }
        }
      )

    assert query_dust == %SqlDust.QueryDust{
      schema: %{
        users: %{
          skills: %{
            macro: :has_and_belongs_to_many,
            primary_key: "identifier"
          }
        },
        relations: %{
          table_name: "users"
        }
      }
    }
  end

  test "throwing an error when generating SQL without having assigned the :from option" do
    assert_raise SqlDust.QueryError, "missing :from option in query dust", fn ->
      SqlDust.Query.select("id")
        |> SqlDust.Query.to_sql
    end
  end

  test "generating SQL using composed query dust" do
    sql = SqlDust.Query.select("id, name")
      |> SqlDust.Query.select("company.name")
      |> SqlDust.Query.from("users")
      |> SqlDust.Query.where("id > 100")
      |> SqlDust.Query.where(["company.name LIKE '%Engel%'"])
      |> SqlDust.Query.order_by("name, company.name")
      |> SqlDust.Query.limit(20)
      |> SqlDust.Query.schema(
        %{
          users: %{"table_name": "people"}
        })
      |> SqlDust.Query.to_sql

    assert sql == """
      SELECT `u`.id, `u`.name, `company`.name
      FROM people `u`
      LEFT JOIN companies `company` ON `company`.id = `u`.company_id
      WHERE (`u`.id > 100) AND (`company`.name LIKE '%Engel%')
      ORDER BY `u`.name, `company`.name
      LIMIT 20
      """
  end
end
