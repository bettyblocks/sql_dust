defmodule SqlDust.QueryTest do
  use ExUnit.Case
  doctest SqlDust.Query
  import SqlDust.Query

  test "select returns SqlDust containing :select option (passing a string)" do
    query_dust = select("id")

    assert query_dust == %SqlDust{
      select: ["id"]
    }
  end

  test "select returns SqlDust containing :select option (passing a list)" do
    query_dust = select(["id"])

    assert query_dust == %SqlDust{
      select: ["id"]
    }
  end

  test "select appends an argument to existing :select option (passing a string)" do
    query_dust = select("id")
      |> select("name")

    assert query_dust == %SqlDust{
      select: ["id", "name"]
    }
  end

  test "select appends an argument to existing :select option (passing a list)" do
    query_dust = select("id")
      |> select(~w(name))

    assert query_dust == %SqlDust{
      select: ["id", "name"]
    }
  end

  test "passing a string to imply the :from option" do
    query_dust = "users"
      |> select("id")

    assert query_dust == %SqlDust{
      select: ["id"],
      from: "users"
    }
  end

  test "from returns SqlDust containing :from option" do
    query_dust = from("users")

    assert query_dust == %SqlDust{
      from: "users"
    }
  end

  test "from sets :from option of passed SqlDust" do
    query_dust = select("id")
      |> from("users")

    assert query_dust == %SqlDust{
      select: ["id"],
      from: "users"
    }
  end

  test "where returns SqlDust containing :where option (passing a string)" do
    query_dust = where("company.name LIKE '%Engel%'")

    assert query_dust == %SqlDust{
      where: ["company.name LIKE '%Engel%'"]
    }
  end

  test "where returns SqlDust containing :where option (passing a list)" do
    query_dust = where(["company.name LIKE '%Engel%'"])

    assert query_dust == %SqlDust{
      where: ["company.name LIKE '%Engel%'"]
    }
  end

  test "where appends an argument to existing :where option (passing a string)" do
    query_dust = where("company.name LIKE '%Engel%'")
      |> where("category_id = 1")

    assert query_dust == %SqlDust{
      where: ["company.name LIKE '%Engel%'", "category_id = 1"]
    }
  end

  test "where appends an argument to existing :where option (passing a list)" do
    query_dust = where("company.name LIKE '%Engel%'")
      |> where(["category_id = 1"])

    assert query_dust == %SqlDust{
      where: ["company.name LIKE '%Engel%'", "category_id = 1"]
    }
  end

  test "group_by returns SqlDust containing :group_by option (passing a string)" do
    query_dust = group_by("company_id")

    assert query_dust == %SqlDust{
      group_by: ["company_id"]
    }
  end

  test "group_by returns SqlDust containing :group_by option (passing a list)" do
    query_dust = group_by(["company_id"])

    assert query_dust == %SqlDust{
      group_by: ["company_id"]
    }
  end

  test "group_by appends an argument to existing :group_by option (passing a string)" do
    query_dust = group_by("company_id")
      |> group_by("category_id")

    assert query_dust == %SqlDust{
      group_by: ["company_id", "category_id"]
    }
  end

  test "group_by appends an argument to existing :group_by option (passing a list)" do
    query_dust = group_by("company_id")
      |> group_by(~w(category_id))

    assert query_dust == %SqlDust{
      group_by: ["company_id", "category_id"]
    }
  end

  test "order_by returns SqlDust containing :order_by option (passing a string)" do
    query_dust = order_by("company_id")

    assert query_dust == %SqlDust{
      order_by: ["company_id"]
    }
  end

  test "order_by returns SqlDust containing :order_by option (passing a list)" do
    query_dust = order_by(["company_id"])

    assert query_dust == %SqlDust{
      order_by: ["company_id"]
    }
  end

  test "order_by appends an argument to existing :order_by option (passing a string)" do
    query_dust = order_by("company_id")
      |> order_by("category_id")

    assert query_dust == %SqlDust{
      order_by: ["company_id", "category_id"]
    }
  end

  test "order_by appends an argument to existing :order_by option (passing a list)" do
    query_dust = order_by("company_id")
      |> order_by(~w(category_id))

    assert query_dust == %SqlDust{
      order_by: ["company_id", "category_id"]
    }
  end

  test "limit returns SqlDust containing :limit option" do
    query_dust = limit(10)

    assert query_dust == %SqlDust{
      limit: 10
    }
  end

  test "limit sets :limit option of passed SqlDust" do
    query_dust = select("id")
      |> limit(10)

    assert query_dust == %SqlDust{
      select: ["id"],
      limit: 10
    }
  end

  test "limit overwrites :limit option within passed SqlDust" do
    query_dust = select("id")
      |> limit(10)
      |> limit(100)

    assert query_dust == %SqlDust{
      select: ["id"],
      limit: 100
    }
  end

  test "schema returns SqlDust containing :schema option" do
    query_dust = schema(%{
      "users": %{
        "skills": %{
          macro: :has_and_belongs_to_many
        }
      }
    })

    assert query_dust == %SqlDust{
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
    query_dust = schema(
        %{
          "users": %{
            "skills": %{
              macro: :has_and_belongs_to_many
            }
          }
        }
      )
      |> schema(
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

    assert query_dust == %SqlDust{
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
    assert_raise RuntimeError, "missing :from option in query dust", fn ->
      select("id")
        |> to_sql
    end
  end

  test "generating SQL using composed query dust" do
    sql = select("id, name")
      |> select("company.name")
      |> from("users")
      |> where("id > 100")
      |> where(["company.name LIKE '%Engel%'"])
      |> order_by("name, company.name")
      |> limit(20)
      |> schema(
        %{
          users: %{"table_name": "people"}
        })
      |> to_sql

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
