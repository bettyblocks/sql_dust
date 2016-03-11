defmodule SqlDustTest do
  use ExUnit.Case
  doctest SqlDust

  test "only passing table" do
    assert SqlDust.from("users") == {"""
      SELECT `u`.*
      FROM users `u`
      """, []}
  end

  test "selecting all columns" do
    assert SqlDust.from("users", %{select: "*"}) == {"""
      SELECT *
      FROM users `u`
      """, []}
  end

  test "selecting all columns of the base resource" do
    assert SqlDust.from("users", %{select: ".*"}) == {"""
      SELECT `u`.*
      FROM users `u`
      """, []}
  end

  test "selecting columns of the base resource (passing a string)" do
    options = %{
      select: "id, first_name, last_name"
    }

    assert SqlDust.from("users", options) == {"""
      SELECT `u`.`id`, `u`.`first_name`, `u`.`last_name`
      FROM users `u`
      """, []}
  end

  test "selecting columns of the base resource (passing a list)" do
    options = %{
      select: ["id", "first_name", "last_name"]
    }

    assert SqlDust.from("users", options) == {"""
      SELECT `u`.`id`, `u`.`first_name`, `u`.`last_name`
      FROM users `u`
      """, []}
  end

  test "interpolating variables" do
    options = %{
      select: ["id", "CONCAT(name, <<postfix>>)"],
      variables: %{postfix: "PostFix!"}
    }

    assert SqlDust.from("users", options) == {
      """
      SELECT `u`.`id`, CONCAT(`u`.`name`, ?)
      FROM users `u`
      """,
      ["PostFix!"]
    }
  end

  test "interpolating variables respects multiple occurrences " do
    options = %{
      select: ["id", "CONCAT(name, <<postfix>>)"],
      where: "foobar LIKE <<postfix>>",
      variables: %{postfix: "PostFix!"}
    }

    assert SqlDust.from("users", options) == {
      """
      SELECT `u`.`id`, CONCAT(`u`.`name`, ?)
      FROM users `u`
      WHERE (`u`.`foobar` LIKE ?)
      """,
      ["PostFix!", "PostFix!"]
    }
  end

  test "using functions" do
    options = %{
      select: "COUNT(*)"
    }

    assert SqlDust.from("users", options) == {"""
      SELECT COUNT(*)
      FROM users `u`
      """, []}
  end

  test "using quoted arguments" do
    options = %{
      select: "id, CONCAT(\"First name: '\", first_name, \"' Last name: '\", last_name, \"'\"), DATE_FORMAT(updated_at, '%d-%m-%Y')"
    }

    assert SqlDust.from("users", options) == {"""
      SELECT
        `u`.`id`,
        CONCAT("First name: '", `u`.`first_name`, "' Last name: '", `u`.`last_name`, "'"),
        DATE_FORMAT(`u`.`updated_at`, '%d-%m-%Y')
      FROM users `u`
      """, []}
  end

  test "selecting columns of a 'belongs to' association" do
    options = %{
      select: "id, first_name, user_role.name, department.id, department.name"
    }

    assert SqlDust.from("users", options) == {"""
      SELECT
        `u`.`id`,
        `u`.`first_name`,
        `user_role`.`name`,
        `department`.`id`,
        `department`.`name`
      FROM users `u`
      LEFT JOIN user_roles `user_role` ON `user_role`.`id` = `u`.`user_role_id`
      LEFT JOIN departments `department` ON `department`.`id` = `u`.`department_id`
      """, []}
  end

  test "selecting columns of a nested 'belongs to' association" do
    options = %{
      select: "id, first_name, company.category.name"
    }

    assert SqlDust.from("users", options) == {"""
      SELECT
        `u`.`id`,
        `u`.`first_name`,
        `company.category`.`name`
      FROM users `u`
      LEFT JOIN companies `company` ON `company`.`id` = `u`.`company_id`
      LEFT JOIN categories `company.category` ON `company.category`.`id` = `company`.`category_id`
      """, []}
  end

  test "selecting columns of a 'has many' association" do
    options = %{
      select: "id, first_name, last_name, GROUP_CONCAT(orders.id)"
    }

    assert SqlDust.from("users", options) == {"""
      SELECT
        `u`.`id`,
        `u`.`first_name`,
        `u`.`last_name`,
        GROUP_CONCAT(`orders`.`id`)
      FROM users `u`
      LEFT JOIN orders `orders` ON `orders`.`user_id` = `u`.`id`
      """, []}
  end

  test "selecting columns of a nested 'has many' association" do
    options = %{
      select: "id, first_name, last_name, GROUP_CONCAT(company.orders.id)"
    }

    assert SqlDust.from("users", options) == {"""
      SELECT
        `u`.`id`,
        `u`.`first_name`,
        `u`.`last_name`,
        GROUP_CONCAT(`company.orders`.`id`)
      FROM users `u`
      LEFT JOIN companies `company` ON `company`.`id` = `u`.`company_id`
      LEFT JOIN orders `company.orders` ON `company.orders`.`company_id` = `company`.`id`
      """, []}
  end

  test "selecting columns of a 'has and belongs to many' association" do
    options = %{
      select: "id, first_name, last_name, GROUP_CONCAT(skills.name)"
    }
    schema = %{
      "users": %{
        "skills": %{
          cardinality: :has_and_belongs_to_many
        }
      }
    }

    assert SqlDust.from("users", options, schema) == {"""
      SELECT
        `u`.`id`,
        `u`.`first_name`,
        `u`.`last_name`,
        GROUP_CONCAT(`skills`.`name`)
      FROM users `u`
      LEFT JOIN skills_users `skills_bridge_table` ON `skills_bridge_table`.`user_id` = `u`.`id`
      LEFT JOIN skills `skills` ON `skills`.`id` = `skills_bridge_table`.`skill_id`
      """, []}
  end

  test "selecting columns of a 'has one' association" do
    options = %{
      select: "id, name, current_price.amount",
      group_by: "id"
    }
    schema = %{
      "products": %{
        current_price: %{
          cardinality: :has_one,
          resource: "prices"
        }
      }
    }

    assert SqlDust.from("products", options, schema) == {"""
      SELECT
        `p`.`id`,
        `p`.`name`,
        `current_price`.`amount`
      FROM products `p`
      LEFT JOIN prices `current_price` ON `current_price`.`product_id` = `p`.`id`
      GROUP BY `p`.`id`
      """, []}
  end

  test "adding join conditions for paths" do
    options = %{
      select: "id, name, current_price.amount",
      join_on: "current_price.latest = 1"
    }
    schema = %{
      "products": %{
        current_price: %{
          cardinality: :has_one,
          resource: "prices"
        }
      }
    }

    assert SqlDust.from("products", options, schema) == {"""
      SELECT
        `p`.`id`,
        `p`.`name`,
        `current_price`.`amount`
      FROM products `p`
      LEFT JOIN prices `current_price` ON `current_price`.`product_id` = `p`.`id` AND `current_price`.`latest` = 1
      """, []}
  end

  test "adding join conditions within the schema" do
    options = %{
      select: "id, name, current_price.amount"
    }
    schema = %{
      "products": %{
        current_price: %{
          cardinality: :has_one,
          resource: "prices",
          join_on: "latest = 1"
        }
      }
    }

    assert SqlDust.from("products", options, schema) == {"""
      SELECT
        `p`.`id`,
        `p`.`name`,
        `current_price`.`amount`
      FROM products `p`
      LEFT JOIN prices `current_price` ON `current_price`.`product_id` = `p`.`id` AND `current_price`.`latest` = 1
      """, []}
  end

  test "adding join conditions within the schema using variables" do
    options = %{
      select: "id, name, current_statistic.amount",
      variables: %{
        "scope": "awesome_scope"
      }
    }
    schema = %{
      "products": %{
        current_statistic: %{
          cardinality: :has_one,
          resource: "statistics",
          join_on: "scope = <<scope>>"
        }
      }
    }

    assert SqlDust.from("products", options, schema) == {
      """
      SELECT
        `p`.`id`,
        `p`.`name`,
        `current_statistic`.`amount`
      FROM products `p`
      LEFT JOIN statistics `current_statistic` ON `current_statistic`.`product_id` = `p`.`id` AND `current_statistic`.`scope` = ?
      """,
      ["awesome_scope"]
    }
  end

  test "selecting columns of a nested 'has and belongs to many' association" do
    options = %{
      select: "id, first_name, last_name, GROUP_CONCAT(company.tags.name)"
    }
    schema = %{
      "companies": %{
        tags: %{
          cardinality: :has_and_belongs_to_many
        }
      }
    }

    assert SqlDust.from("users", options, schema) == {"""
      SELECT
        `u`.`id`,
        `u`.`first_name`,
        `u`.`last_name`,
        GROUP_CONCAT(`company.tags`.`name`)
      FROM users `u`
      LEFT JOIN companies `company` ON `company`.`id` = `u`.`company_id`
      LEFT JOIN companies_tags `company.tags_bridge_table` ON `company.tags_bridge_table`.`company_id` = `company`.`id`
      LEFT JOIN tags `company.tags` ON `company.tags`.`id` = `company.tags_bridge_table`.`tag_id`
      """, []}
  end

  test "overriding the resource table name" do
    schema = %{
      "resellers": %{
        "table_name": "companies"
      }
    }

    assert SqlDust.from("resellers", %{}, schema) == {"""
      SELECT `r`.*
      FROM companies `r`
      """, []}
  end

  test "overriding the resource of an association" do
    options = %{
      select: ["id", "description", "CONCAT(assignee.first_name, ' ', assignee.last_name)"]
    }
    schema = %{
      "issues": %{
        assignee: %{resource: "users"}
      }
    }

    assert SqlDust.from("issues", options, schema) == {"""
      SELECT
        `i`.`id`,
        `i`.`description`,
        CONCAT(`assignee`.`first_name`, ' ', `assignee`.`last_name`)
      FROM issues `i`
      LEFT JOIN users `assignee` ON `assignee`.`id` = `i`.`assignee_id`
      """, []}
  end

  test "overriding the table name of an association" do
    options = %{
      select: ["id", "description", "CONCAT(assignee.first_name, ' ', assignee.last_name)"]
    }
    schema = %{
      "issues": %{
        assignee: %{table_name: "users"}
      }
    }

    assert SqlDust.from("issues", options, schema) == {"""
      SELECT
        `i`.`id`,
        `i`.`description`,
        CONCAT(`assignee`.`first_name`, ' ', `assignee`.`last_name`)
      FROM issues `i`
      LEFT JOIN users `assignee` ON `assignee`.`id` = `i`.`assignee_id`
      """, []}
  end

  test "overriding the bridge table of a has and belongs to many association" do
    options = %{
      select: "id, first_name, last_name, GROUP_CONCAT(skills.name)"
    }
    schema = %{
      "users": %{
        "skills": %{
          cardinality: :has_and_belongs_to_many,
          bridge_table: "skill_set",
          foreign_key: "person_id"
        }
      }
    }

    assert SqlDust.from("users", options, schema) == {"""
      SELECT
        `u`.`id`,
        `u`.`first_name`,
        `u`.`last_name`,
        GROUP_CONCAT(`skills`.`name`)
      FROM users `u`
      LEFT JOIN skill_set `skills_bridge_table` ON `skills_bridge_table`.`person_id` = `u`.`id`
      LEFT JOIN skills `skills` ON `skills`.`id` = `skills_bridge_table`.`skill_id`
      """, []}
  end

  test "grouping the query result" do
    options = %{
      select: ["COUNT(*)"],
      group_by: "category.name"
    }

    assert SqlDust.from("users", options) == {"""
      SELECT COUNT(*)
      FROM users `u`
      LEFT JOIN categories `category` ON `category`.`id` = `u`.`category_id`
      GROUP BY `category`.`name`
      """, []}
  end

  test "ordering the query result (passing a string)" do
    options = %{
      select: ".*",
      order_by: "last_name ASC, first_name"
    }

    assert SqlDust.from("users", options) == {"""
      SELECT `u`.*
      FROM users `u`
      ORDER BY `u`.`last_name` ASC, `u`.`first_name`
      """, []}
  end

  test "ordering the query result (passing a list)" do
    options = %{
      select: ".*",
      order_by: ["last_name ASC", "first_name"]
    }

    assert SqlDust.from("users", options) == {"""
      SELECT `u`.*
      FROM users `u`
      ORDER BY `u`.`last_name` ASC, `u`.`first_name`
      """, []}
  end

  test "limiting the query result" do
    options = %{
      limit: 20
    }

    assert SqlDust.from("users", options) == {"""
      SELECT `u`.*
      FROM users `u`
      LIMIT 20
      """, []}
  end

  test "adding an offset to the query result" do
    options = %{
      limit: 10,
      offset: 20
    }

    assert SqlDust.from("users", options) == {"""
      SELECT `u`.*
      FROM users `u`
      LIMIT 10
      OFFSET 20
      """, []}
  end

  test "quoting SELECT statement aliases" do
    options = %{
      select: "id AS foo.bar",
    }

    assert SqlDust.from("users", options) == {"""
      SELECT `u`.`id` AS `foo.bar`
      FROM users `u`
      """, []}
  end

  test "putting quoted SELECT statement aliases either in the WHERE or HAVING statement" do
    options = %{
      select: "id AS id, CONCAT(first_name, ' ', last_name) AS name, company.name AS company.name",
      where: ["id <= 1982", "name LIKE '%Engel%'", "company.name LIKE '%Inc%'"]
    }

    assert SqlDust.from("users", options) == {"""
      SELECT
        `u`.`id` AS `id`,
        CONCAT(`u`.`first_name`, ' ', `u`.`last_name`) AS `name`,
        `company`.`name` AS `company.name`
      FROM users `u`
      LEFT JOIN companies `company` ON `company`.`id` = `u`.`company_id`
      WHERE (`u`.`id` <= 1982) AND (`company`.`name` LIKE '%Inc%')
      HAVING (`name` LIKE '%Engel%')
      """, []}
  end

  test "respecting preserved word NULL" do
    options = %{
      where: "name IS NOT NULL",
    }

    assert SqlDust.from("users", options) == {"""
      SELECT `u`.*
      FROM users `u`
      WHERE (`u`.`name` IS NOT NULL)
      """, []}
  end

  test "respecting booleans" do
    options = %{
      where: "is_admin = true OR FALSE",
    }

    assert SqlDust.from("users", options) == {"""
      SELECT `u`.*
      FROM users `u`
      WHERE (`u`.`is_admin` = true OR FALSE)
      """, []}
  end

  test "handling '' within WHERE statements" do
    options = %{
      where: "name = ''",
    }

    assert SqlDust.from("users", options) == {"""
      SELECT `u`.*
      FROM users `u`
      WHERE (`u`.`name` = '')
      """, []}
  end

  test "DirectiveRecord example 1 (with additional WHERE statements)" do
    options = %{
      select: "id, name, COUNT(orders.id) AS order.count, GROUP_CONCAT(DISTINCT tags.name) AS tags, foo.tags",
      group_by: "id",
      where: ["name LIKE '%Paul%'", "order.count > 5", "foo.tags = 1"],
      order_by: "COUNT(DISTINCT tags.id) DESC",
      limit: 5
    }
    schema = %{
      customers: %{
        tags: %{
          cardinality: :has_and_belongs_to_many
        }
      }
    }

    assert SqlDust.from("customers", options, schema) == {"""
      SELECT
        `c`.`id`,
        `c`.`name`,
        COUNT(`orders`.`id`) AS `order.count`,
        GROUP_CONCAT(DISTINCT `tags`.`name`) AS `tags`,
        `foo`.`tags`
      FROM customers `c`
      LEFT JOIN orders `orders` ON `orders`.`customer_id` = `c`.`id`
      LEFT JOIN customers_tags `tags_bridge_table` ON `tags_bridge_table`.`customer_id` = `c`.`id`
      LEFT JOIN tags `tags` ON `tags`.`id` = `tags_bridge_table`.`tag_id`
      LEFT JOIN foos `foo` ON `foo`.`id` = `c`.`foo_id`
      WHERE (`c`.`name` LIKE '%Paul%') AND (`foo`.`tags` = 1)
      GROUP BY `c`.`id`
      HAVING (`order.count` > 5)
      ORDER BY COUNT(DISTINCT `tags`.`id`) DESC
      LIMIT 5
      """, []}
  end

  test "DirectiveRecord example 3" do
    options = %{
      where: "tags.name LIKE '%gifts%'"
    }
    schema = %{
      "customers": %{
        tags: %{
          "cardinality": :has_and_belongs_to_many
        }
      }
    }

    assert SqlDust.from("customers", options, schema) == {"""
      SELECT `c`.*
      FROM customers `c`
      LEFT JOIN customers_tags `tags_bridge_table` ON `tags_bridge_table`.`customer_id` = `c`.`id`
      LEFT JOIN tags `tags` ON `tags`.`id` = `tags_bridge_table`.`tag_id`
      WHERE (`tags`.`name` LIKE '%gifts%')
      """, []}
  end

  test "DirectiveRecord example 5" do
    options = %{
      select: "tags.*",
      where: "tags.name LIKE '%gifts%'",
      group_by: "tags.id"
    }
    schema = %{
      customers: %{
        tags: %{
          "cardinality": :has_and_belongs_to_many
        }
      }
    }

    assert SqlDust.from("customers", options, schema) == {"""
      SELECT `tags`.*
      FROM customers `c`
      LEFT JOIN customers_tags `tags_bridge_table` ON `tags_bridge_table`.`customer_id` = `c`.`id`
      LEFT JOIN tags `tags` ON `tags`.`id` = `tags_bridge_table`.`tag_id`
      WHERE (`tags`.`name` LIKE '%gifts%')
      GROUP BY `tags`.`id`
      """, []}
  end

  test "DirectiveRecord example 6" do
    options = %{
      select: ["id", "name", "COUNT(orders.id) AS order_count"],
      where: "order_count > 3",
      group_by: "id"
    }

    assert SqlDust.from("customers", options) == {"""
      SELECT
        `c`.`id`,
        `c`.`name`,
        COUNT(`orders`.`id`) AS `order_count`
      FROM customers `c`
      LEFT JOIN orders `orders` ON `orders`.`customer_id` = `c`.`id`
      GROUP BY `c`.`id`
      HAVING (`order_count` > 3)
      """, []}
  end

  test "prepending path aliases in the HAVING statement while respecting SELECT statement aliases" do
    options = %{
      select: "id AS identifier",
      where: "identifier > 0 AND id != 2",
      order_by: "id"
    }

    assert SqlDust.from("users", options) == {"""
      SELECT `u`.`id` AS `identifier`
      FROM users `u`
      HAVING (`identifier` > 0 AND `u`.`id` != 2)
      ORDER BY `u`.`id`
      """, []}
  end

  test "downcasing base table alias" do
    schema = %{
      User: %{
        table_name: "people"
      }
    }

    assert SqlDust.from("User", %{}, schema) == {"""
      SELECT `u`.*
      FROM people `u`
      """, []}
  end
end
