defmodule SqlDust.JoinUtils do
  alias SqlDust.MapUtils
  import SqlDust.SchemaUtils
  import SqlDust.PathUtils
  import SqlDust.ScanUtils

  def derive_joins(path, options) do
    {path, association} = dissect_path(path, options)

    derive_schema(path, association, options)
      |> derive_table_joins(path, association, options)
      |> compose_join(options)
  end

  defp derive_table_joins(schema1, path, association, options) do
    schema1 = schema1
      |> Map.put(:path, path)

    schema2 = MapUtils.get(schema1, association)
      |> MapUtils.get(:resource, Inflex.pluralize(association))
      |> resource_schema(options)
      |> Map.put(:path, case path do
        "" -> association
        _ -> "#{path}.#{association}"
      end)

    association = MapUtils.get(schema1, association)

    derive_schema_joins(association.cardinality, schema1, schema2, association, options)
  end

  defp derive_schema_joins(:belongs_to = cardinality, schema1, schema2, association, options) do
    %{
      cardinality: cardinality,
      table: association[:table_name] || schema2.table_name,
      path: schema2.path,
      left_key: "#{schema2.path |> quote_alias(options)}.#{association.primary_key |> quote_alias(options)}",
      right_key: "#{schema1.path |> quote_alias(options)}.#{association.foreign_key |> quote_alias(options)}",
      join_on: derive_join_on(schema2.path, association)
    }
  end

  defp derive_schema_joins(:has_one = cardinality, schema1, schema2, association, options) do
    %{
      cardinality: cardinality,
      table: association[:table_name] || schema2.table_name,
      path: schema2.path,
      left_key: "#{schema2.path |> quote_alias(options)}.#{association.foreign_key |> quote_alias(options)}",
      right_key: "#{schema1.path |> quote_alias(options)}.#{association.primary_key |> quote_alias(options)}",
      join_on: derive_join_on(schema2.path, association)
    }
  end

  defp derive_schema_joins(:has_many = cardinality, schema1, schema2, association, options) do
    %{
      cardinality: cardinality,
      table: association[:table_name] || schema2.table_name,
      path: schema2.path,
      left_key: "#{schema2.path |> quote_alias(options)}.#{association.foreign_key |> quote_alias(options)}",
      right_key: "#{schema1.path |> quote_alias(options)}.#{association.primary_key |> quote_alias(options)}",
      join_on: derive_join_on(schema2.path, association)
    }
  end

  defp derive_schema_joins(:has_and_belongs_to_many = cardinality, schema1, schema2, association, options) do
    [
      %{
        cardinality: cardinality,
        table: association.bridge_table,
        path: "#{schema2.path}_bridge_table",
        left_key: "#{quote_alias(schema2.path <> "_bridge_table", options)}.#{quote_alias(association.foreign_key, options)}",
        right_key: "#{quote_alias(schema1.path, options)}.#{quote_alias(association.primary_key, options)}"
      }, %{
        cardinality: cardinality,
        table: schema2.table_name,
        path: schema2.path,
        left_key: "#{quote_alias(schema2.path, options)}.#{quote_alias(association.association_primary_key, options)}",
        right_key: "#{quote_alias(schema2.path <> "_bridge_table", options)}.#{quote_alias(association.association_foreign_key, options)}"
      }
    ]
  end

  defp derive_join_on(path, association) do
    regex = ~r/(?:\.\*|[a-zA-Z]\w+(?:\.(?:\*|\w{2,}))*)/

    association[:join_on]
      |> List.wrap
      |> Enum.map(fn(sql) ->
        {excluded, _} = scan_excluded(sql)
        sql = numerize_patterns(sql, excluded)
        sql = Regex.replace(regex, sql, fn(match) ->
          path <> "." <> match
        end)
        interpolate_patterns(sql, excluded)
      end)
  end

  defp compose_join(table_joins, options) when is_map(table_joins) do
    compose_join([table_joins], options)
  end

  defp compose_join(table_joins, options) do
    table_joins
      |> Enum.map(fn(join) ->
        {left_key, _} = prepend_path_alias(join.left_key, options)
        {right_key, _} = prepend_path_alias(join.right_key, options)
        additional_conditions = join[:join_on]
                                  |> List.wrap
                                  |> Enum.concat(additional_join_conditions(join.path, options))
                                  |> Enum.map(fn(statement) ->
                                    elem prepend_path_aliases(statement, options), 0
                                  end)

        conditions = [left_key <> " = " <> right_key]
                       |> Enum.concat(additional_conditions)
                       |> Enum.join(" AND ")

        {join.cardinality, ["LEFT JOIN", quote_alias(join.table, options), derive_quoted_path_alias(join.path, options), "ON", conditions] |> Enum.join(" ")}
      end)
  end

  defp additional_join_conditions(path, %{join_on: join_on} = options) when is_bitstring(join_on) do
    additional_join_conditions(path, %{options | join_on: [join_on]})
  end

  defp additional_join_conditions(path, %{join_on: join_on} = options) do
    path_alias = derive_quoted_path_alias(path, options)

    join_on
      |> Enum.reduce([], fn(statement, conditions) ->
        {sql, _} = prepend_path_aliases(statement, options)
        if String.contains?(sql, path_alias) do
          conditions |> List.insert_at(-1, statement)
        else
          conditions
        end
      end)
  end

  defp additional_join_conditions(_, _), do: []
end
