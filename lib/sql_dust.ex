defmodule SqlDust do
  import SqlDust.SchemaUtils
  import SqlDust.PathUtils
  import SqlDust.JoinUtils

  @moduledoc """
    SqlDust is a module that generates SQL queries as intuitively as possible.
  """

  def from(resource, options \\ %{}, schema \\ %{}) do
    options = %{
      select: ".*"
    }
      |> Map.merge(options)
      |> Map.merge(%{
        paths: [],
        schema: schema
      })

    options
      |> Map.put(:resource, resource_schema(resource, options))
      |> derive_select
      |> derive_from
      |> derive_joins
      |> compose_sql
  end

  defp derive_select(options) do
    {select, options} = []
      |> List.insert_at(-1, options[:select])
      |> List.flatten
      |> Enum.join(", ")
      |> prepend_path_aliases(options)

    Map.put options, :select, "SELECT #{select}"
  end

  defp derive_from(options) do
    from = "#{options.resource.table_name} #{derive_quoted_path_alias("", options)}"

    Map.put options, :from, "FROM #{from}"
  end

  defp derive_joins(options) do
    joins = options.paths
      |> Enum.uniq
      |> Enum.map(fn(path) -> derive_joins(path, options) end)
      |> List.flatten

    Map.put options, :joins, joins
  end

  defp compose_sql(options) do
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
