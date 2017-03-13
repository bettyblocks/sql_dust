defmodule SqlDust do
  import SqlDust.SchemaUtils
  import SqlDust.ScanUtils
  import SqlDust.PathUtils
  import SqlDust.JoinUtils
  alias SqlDust.MapUtils

  defstruct [:select, :from, :join_on, :where, :group_by, :order_by, :limit, :offset, :unique, :schema, :variables, :adapter]

  @moduledoc """
    SqlDust is a module that generates SQL queries as intuitively as possible.
  """
  def from(resource, options \\ %{}, schema \\ %{}) do
    options = %{
      select: ".*",
      adapter: :mysql,
      initial_variables: options[:variables] || %{},
      variables: %{},
      unique: false
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
      |> derive_join_on
      |> derive_where
      |> derive_group_by
      |> derive_order_by
      |> derive_limit
      |> derive_offset
      |> derive_joins
      |> ensure_unique_records
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
    from = "#{quote_alias(options.resource.table_name, options)} #{derive_quoted_path_alias("", options)}"

    Map.put options, :from, "FROM #{from}"
  end

  defp derive_joins(options) do
    joins = options.paths
      |> Enum.uniq
      |> Enum.map(fn(path) -> derive_joins(path, options) end)
      |> List.flatten

    Map.put options, :joins, joins
  end

  defp derive_join_on(options) do
    if join_on = MapUtils.get(options, :join_on) do
      join_on |> wrap_conditions |> parse_conditions(options, :join_on)
    else
      options
    end
  end

  defp derive_where(%{where: ""} = options), do: Map.put(options, :where, [])
  defp derive_where(%{where: [""]} = options), do: Map.put(options, :where, [])
  defp derive_where(%{where: []} = options), do: options
  defp derive_where(%{where: where} = options) do
    where =
      where
      |> List.wrap()
      |> sanitize_where()
      |> wrap_conditions()

    {having, where} =
      where
      |> Enum.partition(fn([sql | _]) ->
        sql = sanitize_sql(sql)
        Enum.any?(options.aliases, fn(sql_alias) ->
          String.match?(sql, ~r/(^|[^\.\w])#{sql_alias}([^\.\w]|$)/)
        end)
      end)

    options = parse_conditions(where, options, :where)
    options = parse_conditions(having, options, :having)
    options = if length(where) == 0, do: Map.delete(options, :where), else: options

    options
  end
  defp derive_where(options), do: options
  defp sanitize_where(conditions) do
    conditions
    |> Enum.filter(fn(condition) ->
      case condition do
        condition when is_binary(condition) ->
          condition |> String.strip() |> String.length > 0
        [""|_tail] -> false
        _ -> true
      end
    end)
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
      options |> interpolate_option_variable(:limit, limit)
    else
      options
    end
  end

  defp derive_offset(options) do
    if offset = MapUtils.get(options, :offset) do
      options |> interpolate_option_variable(:offset, offset)
    else
      options
    end
  end

  defp ensure_unique_records(options) do
    if options.unique && !MapUtils.get(options, :group_by) && Enum.any?(options.joins, fn(x) -> elem(x, 0) != :belongs_to end) do
      options |> Map.put(:group_by, "id") |> derive_group_by
    else
      options
    end
  end

  defp wrap_conditions(conditions) do
    conditions = List.wrap(conditions)
    [head | tail] = conditions

    if is_bitstring(head) && (length(Regex.scan(~r/\?/, head)) == length(tail)) do
      [conditions]
    else
      Enum.map(conditions, fn(statement) -> List.wrap(statement) end)
    end
  end

  defp parse_conditions([], options, _), do: options
  defp parse_conditions(conditions, options, key) when key in [:where, :having] do
    {conditions, options} = Enum.reduce(conditions, {[], options}, fn([sql | values], {conditions, options}) ->
                              {sql, options} = prepend_path_aliases("(" <> sql <> ")", options)
                              {List.insert_at(conditions, -1, [sql] |> Enum.concat(values)), options}
                            end)
    parse_conditions(conditions, options, key, true)
  end

  defp parse_conditions(conditions, options, key, _ \\ true) do
    {conditions, options} = Enum.reduce(conditions, {[], options}, fn([sql | values], {conditions, options}) ->

                              {sql, variables} = values
                                                 |> Enum.reduce({sql, options.variables}, fn(value, {sql, variables}) ->
                                                   key = "__" <> to_string(Map.size(variables) + 1) <> "__"
                                                   variables = Map.put(variables, key, value)
                                                   sql = String.replace(sql, "?", "<<" <> key <> ">>", global: false)
                                                   {sql, variables}
                                                 end)

                              options = Map.put(options, :variables, variables)
                              {List.insert_at(conditions, -1, sql), options}
                            end)

    prefix = if key in [:where, :having], do: (Atom.to_string(key) |> String.upcase) <> " ", else: ""
    Map.put(options, key, prefix <> (conditions |> Enum.join(" AND ")))
  end

  defp interpolate_option_variable(options, key, value) do
    variables = options.variables

    variables =
      unless value == "?" do
        option_variables = (options.variables[:_options_] || %{}) |> Map.put(key, value)
        options.variables |> Map.put(:_options_, option_variables)
      else
        variables
      end

    interpolated_key = "<<_options_." <> Atom.to_string(key)

    options
      |> Map.put(key, (Atom.to_string(key) |> String.upcase) <> " " <> interpolated_key <> ">>")
      |> Map.put(:variables, variables)
  end

  defp compose_sql(options) do
    [
      options.select,
      options.from,
      options.joins |> Enum.map(
        fn(x) -> elem(x, 1) end
      ),
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
      |> interpolate_variables(options.variables, options.initial_variables)
  end
end
