defmodule SqlDust.JoinUtils do
  alias SqlDust.MapUtils, as: MapUtils

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

    schema3 = MapUtils.get(schema1, association)

    case MapUtils.get(schema1, association).macro do
      :belongs_to -> derive_belongs_to_joins(schema1, schema2, schema3)
      :has_many -> derive_has_many_joins(schema1, schema2, schema3)
      :has_and_belongs_to_many -> derive_has_and_belongs_to_many_joins(schema1, schema2, schema3)
    end
  end

  defp derive_belongs_to_joins(schema1, schema2, association) do
    %{
      table: schema2.table_name,
      path: schema2.path,
      primary_key: "#{schema2.path}.#{association.primary_key}",
      foreign_key: "#{schema1.path}.#{association.foreign_key}"
    }
  end

  defp derive_has_many_joins(schema1, schema2, association) do
    %{
      table: schema2.table_name,
      path: schema2.path,
      primary_key: "#{schema2.path}.#{association.primary_key}",
      foreign_key: "#{schema1.path}.#{association.foreign_key}"
    }
  end

  defp derive_has_and_belongs_to_many_joins(schema1, schema2, _) do
    bridge_table_path = "#{schema2.path}_bridge_table"

    bridge_table = [schema1.table_name, schema2.table_name]
      |> Enum.sort
      |> Enum.join("_")

    [
      %{
        table: bridge_table,
        path: bridge_table_path,
        primary_key: "#{bridge_table_path}.#{Inflex.singularize schema1.name}_id",
        foreign_key: "#{schema1.path}.id"
      }, %{
        table: schema2.table_name,
        path: schema2.path,
        primary_key: "#{schema2.path}.id",
        foreign_key: "#{bridge_table_path}.#{Inflex.singularize schema2.name}_id"
      }
    ]
  end

  defp compose_sql(table_joins, options) when is_map(table_joins) do
    compose_sql([table_joins], options)
  end

  defp compose_sql(table_joins, options) do
    table_joins
      |> Enum.map(fn(join) ->
        {primary_key, _} = prepend_path_alias(join.primary_key, options)
        {foreign_key, _} = prepend_path_alias(join.foreign_key, options)
        [
          "LEFT JOIN", join.table, derive_quoted_path_alias(join.path, options),
          "ON", primary_key, "=", foreign_key
        ] |> Enum.join(" ")
      end)
  end
end
