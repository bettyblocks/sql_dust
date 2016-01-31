defmodule SqlDustTest do
  use ExUnit.Case
  doctest SqlDust

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

  test "selecting all columns of the base resource" do
    assert SqlDust.from("users", %{select: ".*"}) == """
      SELECT `u`.*
      FROM users `u`
      """
  end

  test "selecting columns of the base resource (passing a string)" do
    options = %{
      select: "id, first_name, last_name"
    }
    assert SqlDust.from("users", options) == """
      SELECT `u`.id, `u`.first_name, `u`.last_name
      FROM users `u`
      """
  end

  test "selecting columns of the base resource (passing a list)" do
    options = %{
      select: ["id", "first_name", "last_name"]
    }
    assert SqlDust.from("users", options) == """
      SELECT `u`.id, `u`.first_name, `u`.last_name
      FROM users `u`
      """
  end

  test "using functions" do
    options = %{
      select: "COUNT(*)"
    }
    assert SqlDust.from("users", options) == """
      SELECT COUNT(*)
      FROM users `u`
      """
  end

  test "using quoted arguments" do
    options = %{
      select: "id, CONCAT(\"First name: '\", first_name, \"' Last name: '\", last_name, \"'\"), DATE_FORMAT(updated_at, '%d-%m-%Y')"
    }
    assert SqlDust.from("users", options) == """
      SELECT `u`.id, CONCAT("First name: '", `u`.first_name, "' Last name: '", `u`.last_name, "'"), DATE_FORMAT(`u`.updated_at, '%d-%m-%Y')
      FROM users `u`
      """
  end

  test "selecting columns of a 'belongs to' association" do
    options = %{
      select: "id, first_name, user_role.name, department.id, department.name"
    }
    assert SqlDust.from("users", options) == """
      SELECT `u`.id, `u`.first_name, `user_role`.name, `department`.id, `department`.name
      FROM users `u`
      LEFT JOIN user_roles `user_role` ON `user_role`.id = `u`.user_role_id
      LEFT JOIN departments `department` ON `department`.id = `u`.department_id
      """
  end

  test "selecting columns of a nested 'belongs to' association" do
    options = %{
      select: "id, first_name, company.category.name"
    }
    assert SqlDust.from("users", options) == """
      SELECT `u`.id, `u`.first_name, `company.category`.name
      FROM users `u`
      LEFT JOIN companies `company` ON `company`.id = `u`.company_id
      LEFT JOIN categories `company.category` ON `company.category`.id = `company`.category_id
      """
  end

  test "selecting columns of a 'has many' association" do
    options = %{
      select: "id, first_name, last_name, GROUP_CONCAT(orders.id)"
    }
    assert SqlDust.from("users", options) == """
      SELECT `u`.id, `u`.first_name, `u`.last_name, GROUP_CONCAT(`orders`.id)
      FROM users `u`
      LEFT JOIN orders `orders` ON `orders`.user_id = `u`.id
      """
  end

  test "select columns of a 'has and belongs to many' association" do
    options = %{
      select: "id, first_name, last_name, GROUP_CONCAT(skills.name)"
    }
    schema = %{
      "users": %{
        "skills": %{macro: :has_and_belongs_to_many}
      }
    }
    assert SqlDust.from("users", options, schema) == """
      SELECT `u`.id, `u`.first_name, `u`.last_name, GROUP_CONCAT(`skills`.name)
      FROM users `u`
      LEFT JOIN users_skills `skills_bridge_table` ON `skills_bridge_table`.user_id = `u`.id
      LEFT JOIN skills `skills` ON `skills`.id = `skills_bridge_table`.skill_id
      """
  end
end
