defmodule SqlDustTest do
  use ExUnit.Case
  doctest SqlDust

  @tag token: "from"
  test "generates a simple SQL query" do
    assert SqlDust.from("users") == """
      SELECT `u`.*
      FROM users `u`
      """
  end

  test "respects passed SELECT statements" do
    sql = """
      SELECT `u`.id, `u`.first_name, `u`.last_name
      FROM users `u`
      """

    options = %{select: "id, first_name, last_name"}
    assert SqlDust.from("users", options) == sql

    options = %{select: ["id", "first_name", "last_name"]}
    assert SqlDust.from("users", options) == sql
  end
end
