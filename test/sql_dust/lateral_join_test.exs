defmodule SqlDust.LateralJoinTest do
  use ExUnit.Case

  import SqlDust.Query

  test "laterl join returns join" do
    sub_dust = select("id") |> from("account") |> where("id = 1")
    query_dust = select("id") |> from("users") |> join_lateral("sub_table", sub_dust)

    assert query_dust |> to_sql |> elem(0) == "SELECT `u`.`id`\nFROM `users` `u`\nLEFT JOIN LATERAL ( SELECT `a`.`id`\nFROM `account` `a`\nWHERE (`a`.`id` = 1)\n ) AS sub_table ON TRUE\n"
  end


  test "laterl join alias doesn't get ignored" do
    sub_dust = select("id", "user_id") |> from("account") |> where("id = 1")
    query_dust = select("id") |> from("users") |> join_lateral("sub_table", sub_dust) |> where("sub_table.user_id = id")

    assert query_dust |> to_sql |> elem(0) == "SELECT `u`.`id`\nFROM `users` `u`\nLEFT JOIN LATERAL ( SELECT `a`.`user_id`\nFROM `account` `a`\nWHERE (`a`.`id` = 1)\n ) AS sub_table ON TRUE\nWHERE (sub_table.\"user_id\" = `u`.`id`)\n"
  end
end
