defmodule SqlDust do
  alias SqlDust.MapUtils, as: MapUtils

  import SqlDust.SchemaUtils
  import SqlDust.ScanUtils
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
      |> derive_group_by
      |> derive_order_by
      |> derive_limit
      |> derive_joins
      |> compose_sql
  end

  defp derive_select(options) do
    {select, options} = []
      |> List.insert_at(-1, options[:select])
      |> List.flatten
      |> Enum.join(", ")
      |> split_arguments
      |> prepend_path_aliases(options)

    prefix = if String.length(Enum.join(select, ", ")) > 45 do
      "\n  "
    else
      " "
    end

    select = select
      |> Enum.map(fn(sql) -> "#{prefix}#{sql}" end)
      |> Enum.join(",")

    Map.put options, :select, "SELECT#{select}"
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

  defp derive_group_by(options) do
    if group_by = MapUtils.get(options, :group_by) do
      {group_by, options} = prepend_path_aliases(group_by, options)
      Map.put(options, :group_by, "GROUP BY #{group_by}")
    else
      options
    end
  end

  defp derive_order_by(options) do
    if order_by = MapUtils.get(options, :order_by) do
      {order_by, options} = prepend_path_aliases(order_by, options)
      Map.put(options, :order_by, "ORDER BY #{order_by}")
    else
      options
    end
  end

  defp derive_limit(options) do
    if limit = MapUtils.get(options, :limit) do
      Map.put(options, :limit, "LIMIT #{limit}")
    else
      options
    end
  end

  defp compose_sql(options) do
    [
      options.select,
      options.from,
      options.joins,
      options[:group_by],
      options[:order_by],
      options[:limit],
      ""
    ]
      |> List.flatten
      |> Enum.reject(
        fn(x) -> is_nil(x) end
      )
      |> Enum.join("\n")
  end
end
