defmodule SqlDust do
  import SqlDust.Utils

  @moduledoc """
    SqlDust is a module that generates SQL queries as intuitively as possible.
  """

  def from(table, options \\ %{}) do
    %{
      select: ".*",
      from: table,
      paths: [],
      joins: %{}
    }
      |> Map.merge(options)
      |> derive_select
      |> derive_joins
      |> compose
  end

  defp derive_select(options) do
    {select, options} = []
      |> List.insert_at(-1, options[:select])
      |> List.flatten
      |> Enum.join(", ")
      |> split_arguments
      |> prepend_path_alias(options)

    Dict.put options, :select, select
  end

  defp derive_joins(options) do
    joins = options.paths
      |> Enum.uniq
      |> Enum.map(fn(path) -> derive_join(path, options) end)

    Dict.put options, :joins, joins
  end

  defp compose(options) do
    sql = [
      "SELECT #{Enum.join(options.select, ", ")}",
      "FROM #{options.from} #{quote_alias derive_path_alias(options)}"
    ]

    sql = Enum.reduce(options.joins, sql, fn(join, sql) ->
      join_sql = Enum.join([
        "LEFT JOIN",
        join.table,
        "ON",
        join.primary_key,
        "=",
        join.foreign_key
      ], " ")
      List.insert_at(sql, -1, join_sql)
    end)

    "#{Enum.join(sql, "\n")}\n"
  end
end
