defmodule SqlDust.JoinUtils do
  alias SqlDust.MapUtils
  import SqlDust.SchemaUtils
  import SqlDust.PathUtils

  def derive_joins(path, options) do
    {path, association} = dissect_path(path)

    derive_schema(path, association, options)
      |> derive_table_joins(path, association, options)
      |> compose_sql(options)
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

    derive_schema_joins(association.macro, schema1, schema2, association)
  end

  defp derive_schema_joins(macro, schema1, schema2, association) when macro == :belongs_to do
    %{
      table: association[:table_name] || schema2.table_name,
      path: schema2.path,
      left_key: "#{schema2.path}.#{association.primary_key}",
      right_key: "#{schema1.path}.#{association.foreign_key}"
    }
  end

  defp derive_schema_joins(macro, schema1, schema2, association) when macro == :has_one do
    %{
      table: association[:table_name] || schema2.table_name,
      path: schema2.path,
      left_key: "#{schema2.path}.#{association.primary_key}",
      right_key: "#{schema1.path}.#{association.foreign_key}"
    }
  end

  defp derive_schema_joins(macro, schema1, schema2, association) when macro == :has_many do
    %{
      table: association[:table_name] || schema2.table_name,
      path: schema2.path,
      left_key: "#{schema2.path}.#{association.foreign_key}",
      right_key: "#{schema1.path}.#{association.primary_key}"
    }
  end

  defp derive_schema_joins(macro, schema1, schema2, association) when macro == :has_and_belongs_to_many do
    [
      %{
        table: association.bridge_table,
        path: "#{schema2.path}_bridge_table",
        left_key: "#{schema2.path}_bridge_table.#{association.foreign_key}",
        right_key: "#{schema1.path}.#{association.primary_key}"
      }, %{
        table: schema2.table_name,
        path: schema2.path,
        left_key: "#{schema2.path}.#{association.association_primary_key}",
        right_key: "#{schema2.path}_bridge_table.#{association.association_foreign_key}"
      }
    ]
  end

  defp compose_sql(table_joins, options) when is_map(table_joins) do
    compose_sql([table_joins], options)
  end

  defp compose_sql(table_joins, options) do
    table_joins
      |> Enum.map(fn(join) ->
        {left_key, _} = prepend_path_alias(join.left_key, options)
        {right_key, _} = prepend_path_alias(join.right_key, options)
        [
          "LEFT JOIN", join.table, derive_quoted_path_alias(join.path, options),
          "ON", left_key, "=", right_key
        ] |> Enum.join(" ")
      end)
  end
end
