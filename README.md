# SqlDust [![Hex.pm](https://img.shields.io/hexpm/v/sql_dust.svg)](https://hex.pm/packages/sql_dust) [![Hex.pm](https://img.shields.io/hexpm/dt/sql_dust.svg)](https://hex.pm/packages/sql_dust) [![Build Status](https://travis-ci.org/archan937/sql_dust.svg?branch=master)](https://travis-ci.org/archan937/sql_dust) [![Inline docs](http://inch-ci.org/github/archan937/sql_dust.svg)](http://inch-ci.org/github/archan937/sql_dust)

Easy. Simple. Powerful. Generate (complex) SQL queries using magical Elixir SQL dust.

## Introduction

Every language has its commonly used libraries / gems / packages to interact with databases. Ruby has [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord) and Elixir has [Ecto](https://github.com/elixir-lang/ecto). They provide a lot of functionality which are very useful but when it comes to quickly and easily querying tabular data they require too much hassle:

* you have to describe models representing tables ([example](https://github.com/elixir-lang/ecto/blob/master/examples/simple/lib/simple.ex))
* you have to describe how to join tables ([example](https://blog.drewolson.org/composable-queries-ecto))
* using the query DSL requires a bit of reading and understanding how to use it

Actually, you do not want to waste time specifying how to join tables and thinking about table aliases when you have followed the standard naming convention. And you do not want to think about putting a condition in the `WHERE` or `HAVING` statement.

The solution is to think in **paths** (e.g. `company.tags.name`) and letting the package do the magic regarding joining table and to use `SELECT` statement aliases to determine `HAVING` statements.

Enter `SqlDust`. It makes it as easy and simple as possible for the developer to generate SQL queries:

* no models setup
* no joins specifications
* no DSL to learn

Just focus on what really matters! ;)

### Examples

Based on standard naming conventions, `SqlDust` will determine how to join tables. You just have to specify from which resource (table) to query from and which columns to select using paths:

```elixir
iex(1)> IO.puts SqlDust.from("users", %{select: ~w(id first_name company.category.name)})
SELECT
  `u`.id,
  `u`.first_name,
  `company.category`.name
FROM users `u`
LEFT JOIN companies `company` ON `company`.id = `u`.company_id
LEFT JOIN categories `company.category` ON `company.category`.id = `company`.category_id

:ok
iex(2)>
```

Composable queries are also possible:

```elixir
iex(1)> import SqlDust.Query
nil
iex(2)> select("id, last_name, first_name") |> from("users") |> where("company.id = 1982") |> to_sql |> IO.puts
SELECT `u`.id, `u`.last_name, `u`.first_name
FROM users `u`
LEFT JOIN companies `company` ON `company`.id = `u`.company_id
WHERE (`company`.id = 1982)

:ok
iex(3)> "users" |> adapter(:postgres) |> to_sql |> IO.puts
SELECT "u".*
FROM users "u"

:ok
iex(4)>
```

Composable queries using [Ecto](https://github.com/elixir-lang/ecto) models are also possible (using [Ecto simple example](https://github.com/elixir-lang/ecto/blob/master/examples/simple/lib/simple.ex)):

```elixir
iex(1)> import Ecto.SqlDust
nil
iex(2)> Weather |> to_sql |> IO.puts
SELECT "w".*
FROM weather "w"

:ok
iex(3)> City |> select("id, name, country.name") |> where("country.name = 'United States'") |> to_sql |> IO.puts
SELECT "c".id, "c".name, "country".name
FROM cities "c"
LEFT JOIN countries "country" ON "country".id = "c".country_id
WHERE ("country".name = 'United States')

:ok
iex(4)>
```

## Installation

To install SqlDust, please do the following:

  1. Add sql_dust to your list of dependencies in `mix.exs`:

        def deps do
          [{:sql_dust, "~> 0.1.7"}]
        end

  2. Ensure sql_dust is started before your application:

        def application do
          [applications: [:sql_dust]]
        end

## Usage

Generating SQL queries has never been simpler. Just invoke the `SqlDust.from/3` function. It accepts the following arguments:

* `resource` (required) - Usually this is the table from which you want to query from
* `options` (required) - A map containing info about what the query should contain (e.g. `:select`, `:where`, `:group_by`)
* `schema` (optional) - A map containing info which overrule the defacto derived schema

```elixir
options = %{
  select: "id, name, COUNT(orders.id) AS order_count, GROUP_CONCAT(DISTINCT tags.name) AS tags, foo.tags",
  group_by: "id",
  where: ["name LIKE '%Paul%'", "order_count > 5", "foo.tags = 1"],
  order_by: "COUNT(DISTINCT tags.id) DESC",
  limit: 5
}

schema = %{
  customers: %{
    tags: %{
      macro: :has_and_belongs_to_many
    }
  }
}

SqlDust.from("customers", options, schema) |> IO.puts

"""
SELECT
  `c`.id,
  `c`.name,
  COUNT(`orders`.id) AS order_count,
  GROUP_CONCAT(DISTINCT `tags`.name) AS tags,
  `foo`.tags
FROM customers `c`
LEFT JOIN orders `orders` ON `orders`.customer_id = `c`.id
LEFT JOIN customers_tags `tags_bridge_table` ON `tags_bridge_table`.customer_id = `c`.id
LEFT JOIN tags `tags` ON `tags`.id = `tags_bridge_table`.tag_id
LEFT JOIN foos `foo` ON `foo`.id = `c`.foo_id
WHERE (`c`.name LIKE '%Paul%') AND (`foo`.tags = 1)
GROUP BY `c`.id
HAVING (order_count > 5)
ORDER BY COUNT(DISTINCT `tags`.id) DESC
LIMIT 5
"""
```

### Composable queries

As of version `0.1.0`, it is to possible compose queries (thanks to [Justin Workman](https://github.com/xtagon) for the request):

```elixir
import SqlDust.Query

select("id, last_name, first_name")
  |> from("users")
  |> where("company.id = 1982")
  |> where("last_name LIKE '%Engel%'")
  |> order_by(["last_name", "first_name"])
  |> to_sql
  |> IO.puts

"""
SELECT `u`.id, `u`.last_name, `u`.first_name
FROM users `u`
LEFT JOIN companies `company` ON `company`.id = `u`.company_id
WHERE (`company`.id = 1982) AND (`u`.last_name LIKE '%Engel%')
ORDER BY `u`.last_name, `u`.first_name
"""
```

### Composable queries using Ecto models

As of version `0.1.1`, it is to possible compose queries using Ecto(!) models:

```elixir
import Ecto.SqlDust

City
  |> select("id, name, country.name, local_weather.temp_lo, local_weather.temp_hi")
  |> where("local_weather.wdate = '2015-09-12'")
  |> to_sql
  |> IO.puts

"""
SELECT
  "c".id,
  "c".name,
  "country".name,
  "local_weather".temp_lo,
  "local_weather".temp_hi
FROM cities "c"
LEFT JOIN countries "country" ON "country".id = "c".country_id
LEFT JOIN weather "local_weather" ON "local_weather".city_id = "c".id
WHERE ("local_weather".wdate = '2015-09-12')
"""
```

### MySQL versus Postgres

At default, SqlDust generates queries with MySQL quotations except for when using Ecto models because then it defaults to Postgres. You can specify the adapter using the `adapter` function after having piped the Ecto model:

```elixir
import Ecto.SqlDust

City
  |> select("id, name")
  |> adapter(:mysql)
  |> to_sql
  |> IO.puts

"""
SELECT `c`.id, `c`.name
FROM cities `c`
"""
```

SqlDust should automatically determine the correct database adapter of the Ecto model of course. So that will be added in the following release.

Enjoy using SqlDust! ^^

## Testing

Run the following command for testing:

    mix test

All the SqlDust features are tested in [test/sql_dust_test.exs](https://github.com/archan937/sql_dust/blob/master/test/sql_dust_test.exs), [test/sql_dust/query_test.exs](https://github.com/archan937/sql_dust/blob/master/test/sql_dust/query_test.exs) and [test/ecto/sql_dust_test.exs](https://github.com/archan937/sql_dust/blob/master/test/ecto/sql_dust_test.exs).

## Nice To Have

* Query from the database

## TODO

* Prevent SQL injection attacks
* Automatically derive database adapter using `Ecto.Repo`
* Support `has through` associations
* Support polymorphic associations
* Add additional documentation to the README
* Add doc tests for internal functions

## License

Copyright (c) 2016 Paul Engel, released under the MIT License

http://github.com/archan937 – http://twitter.com/archan937 – pm_engel@icloud.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
