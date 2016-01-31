defmodule SqlDust.JoinUtils do
  alias SqlDust.MapUtils, as: MapUtils

  import SqlDust.SchemaUtils
  import SqlDust.PathUtils

  def derive_joins(path, options) do
    {path, association} = dissect_path(path)

    derive_schema(path, association, options)
      |> derive_table_joins(path, association, options)
      |> compose_sql
  end

  defp derive_table_joins(schema1, path, association, options) do
    schema2 = derive_schema(Inflex.pluralize(association), "", options)

    schema1 = Map.merge(schema1, %{
      path: path,
      table_alias: derive_quoted_path_alias(path, options)
    })

    path = case path do
      "" -> association
      _ -> "#{path}.#{association}"
    end

    schema2 = Map.merge(schema2, %{
      path: path,
      association: association,
      table_alias: derive_quoted_path_alias(path, options)
    })

    case MapUtils.get(schema1, association).macro do
      :belongs_to -> derive_belongs_to_joins(schema1, schema2)
      :has_many -> derive_has_many_joins(schema1, schema2)
      :has_and_belongs_to_many -> derive_has_and_belongs_to_many_joins(schema1, schema2, options)
    end
  end

  defp derive_belongs_to_joins(schema1, schema2) do
    %{
      table: schema2.table_name,
      table_alias: schema2.table_alias,
      primary_key: "#{schema2.table_alias}.id",
      foreign_key: "#{schema1.table_alias}.#{schema2.association}_id"
    }
  end

  defp derive_has_many_joins(schema1, schema2) do
    %{
      table: schema2.table_name,
      table_alias: schema2.table_alias,
      primary_key: "#{schema2.table_alias}.#{Inflex.singularize schema1.resource}_id",
      foreign_key: "#{schema1.table_alias}.id"
    }
  end

  defp derive_has_and_belongs_to_many_joins(schema1, schema2, options) do
    [
      %{
        table: "#{schema1.table_name}_#{schema2.table_name}",
        table_alias: derive_quoted_path_alias("#{schema2.path}_bridge_table", options),
        primary_key: "#{derive_quoted_path_alias("#{schema2.path}_bridge_table", options)}.#{Inflex.singularize schema1.resource}_id",
        foreign_key: "#{schema1.table_alias}.id"
      }, %{
        table: schema2.table_name,
        table_alias: schema2.table_alias,
        primary_key: "#{schema2.table_alias}.id",
        foreign_key: "#{derive_quoted_path_alias("#{schema2.path}_bridge_table", options)}.#{Inflex.singularize schema2.resource}_id"
      }
    ]
  end

  defp compose_sql(table_joins) when is_map(table_joins) do
    compose_sql([table_joins])
  end

  defp compose_sql(table_joins) do
    table_joins
      |> Enum.map(fn(join) ->
        "LEFT JOIN #{join.table} #{join.table_alias} ON #{join.primary_key} = #{join.foreign_key}"
      end)
  end
end
