defmodule SqlDust do
  import SqlDust.SchemaUtils
  import SqlDust.ScanUtils
  import SqlDust.PathUtils
  import SqlDust.JoinUtils
  alias SqlDust.MapUtils

  defstruct [:select, :from, :where, :group_by, :order_by, :limit, :offset, :schema, :adapter]

  @moduledoc """
    SqlDust is a module that generates SQL queries as intuitively as possible.
  """

  def from(resource, options \\ %{}, schema \\ %{}) do
    options = %{
      select: ".*",
      adapter: :mysql
    }
      |> Map.merge(options)
      |> Map.merge(%{
        aliases: [],
        paths: [],
        schema: schema
      })

    options
      |> Map.put(:resource, resource_schema(resource, options))
      |> derive_select
      |> derive_from
      |> derive_where
      |> derive_group_by
      |> derive_order_by
      |> derive_limit
      |> derive_offset
      |> derive_joins
      |> compose_sql
  end

  defp derive_select(options) do
    list = split_arguments(options[:select])

    {select, options} = list
      |> prepend_path_aliases(options)

    options = Map.put(options, :aliases, Enum.reject(options.aliases, fn(sql_alias) ->
                Enum.member?(list, sql_alias <> " AS " <> sql_alias)
              end))

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

  defp derive_where(options) do
    if where = MapUtils.get(options, :where) do
      {having, where} = [where]
        |> List.flatten
        |> Enum.map(fn(sql) -> "(#{sql})" end)
        |> Enum.partition(fn(sql) ->
          sql = sanitize_sql(sql)
          Enum.any?(options.aliases, fn(sql_alias) ->
            String.match?(sql, ~r/[^\.\w]#{sql_alias}[^\.\w]/)
          end)
        end)

      {where, options} = prepend_path_aliases(where, options)
      {having, options} = prepend_path_aliases(having, options)

      if length(where) > 0 do
        options = Map.put(options, :where, "WHERE #{where |> Enum.join(" AND ")}")
      else
        options = Map.delete(options, :where)
      end

      if length(having) > 0 do
        options = Map.put(options, :having, "HAVING #{having |> Enum.join(" AND ")}")
      end
    end

    options
  end

  defp derive_group_by(options) do
    if group_by = MapUtils.get(options, :group_by) do
      {group_by, options} = group_by
        |> split_arguments
        |> prepend_path_aliases(options)

      Map.put(options, :group_by, "GROUP BY #{group_by |> Enum.join(", ")}")
    else
      options
    end
  end

  defp derive_order_by(options) do
    if order_by = MapUtils.get(options, :order_by) do
      {order_by, options} = order_by
        |> split_arguments
        |> prepend_path_aliases(options)

      Map.put(options, :order_by, "ORDER BY #{order_by |> Enum.join(", ")}")
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

  defp derive_offset(options) do
    if offset = MapUtils.get(options, :offset) do
      Map.put(options, :offset, "OFFSET #{offset}")
    else
      options
    end
  end

  defp compose_sql(options) do
    [
      options.select,
      options.from,
      options.joins,
      options[:where],
      options[:group_by],
      options[:having],
      options[:order_by],
      options[:limit],
      options[:offset],
      ""
    ]
      |> List.flatten
      |> Enum.reject(
        fn(x) -> is_nil(x) end
      )
      |> Enum.join("\n")
  end
end
