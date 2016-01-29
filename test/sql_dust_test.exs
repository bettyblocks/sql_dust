defmodule SqlDustTest do
  use ExUnit.Case
  doctest SqlDust

  @tag token: "from"

  test "only passing table" do
    assert SqlDust.from("users") == """
      SELECT `u`.*
      FROM users `u`
      """
  end

  test "selecting all columns" do
    assert SqlDust.from("users", %{select: "*"}) == """
      SELECT *
      FROM users `u`
      """
  end

  test "selecting all columns of the base table" do
    assert SqlDust.from("users", %{select: ".*"}) == """
      SELECT `u`.*
      FROM users `u`
      """
  end

  test "selecting columns of the base table (passing a string)" do
    options = %{select: "id, first_name, last_name"}
    assert SqlDust.from("users", options) == """
      SELECT `u`.id, `u`.first_name, `u`.last_name
      FROM users `u`
      """
  end

  test "selecting columns of the base table (passing a list)" do
    options = %{select: ["id", "first_name", "last_name"]}
    assert SqlDust.from("users", options) == """
      SELECT `u`.id, `u`.first_name, `u`.last_name
      FROM users `u`
      """
  end

  test "selecting columns of a 'belongs to' association" do
    options = %{select: "id, first_name, user_role.name, department.id, department.name"}
    assert SqlDust.from("users", options) == """
      SELECT `u`.id, `u`.first_name, `user_role`.name, `department`.id, `department`.name
      FROM users `u`
      LEFT JOIN user_roles `user_role` ON `user_role`.id = `u`.user_role_id
      LEFT JOIN departments `department` ON `department`.id = `u`.department_id
      """
  end

  test "selecting columns of a 'has many' association" do
    options = %{select: "id, first_name, orders.id"}
    assert SqlDust.from("users", options) == """
      SELECT `u`.id, `u`.first_name, `orders`.id
      FROM users `u`
      LEFT JOIN orders `orders` ON `orders`.user_id = `u`.id
      """
  end
end
