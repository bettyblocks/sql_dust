defmodule SqlDust do
  import SqlDust.PathUtils
  import SqlDust.JoinUtils

  @moduledoc """
    SqlDust is a module that generates SQL queries as intuitively as possible.
  """

  def from(table, options \\ %{}) do
    %{
      select: ".*",
      table: table,
      paths: [],
      joins: %{}
    }
      |> Map.merge(options)
      |> derive_select
      |> derive_from
      |> derive_joins
      |> compose
  end

  defp derive_select(options) do
    {select, options} = []
      |> List.insert_at(-1, options[:select])
      |> List.flatten
      |> Enum.join(", ")
      |> prepend_path_aliases(options)

    Dict.put options, :select, "SELECT #{select}"
  end

  defp derive_from(options) do
    from = "#{options.table} #{derive_quoted_path_alias(options)}"

    Dict.put options, :from, "FROM #{from}"
  end

  defp derive_joins(options) do
    joins = options.paths
      |> Enum.uniq
      |> Enum.map(fn(path) -> derive_join(path, options) end)

    Dict.put options, :joins, joins
  end

  defp compose(options) do
    [
      options.select,
      options.from,
      options.joins,
      ""
    ]
      |> List.flatten
      |> Enum.join("\n")
  end
end
