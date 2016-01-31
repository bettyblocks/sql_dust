defmodule SqlDust.JoinUtils do
  alias SqlDust.MapUtils, as: MapUtils
  import SqlDust.PathUtils

  def derive_joins(path, options) do
    {prefix, association, _} = dissect_path(path)

    derive_schema(prefix, association, options)
      |> derive_table_joins(prefix, association, options)
      |> compose_sql
  end

  defp derive_schema(path, association, options) when is_bitstring(path) do
    String.split(path, ".")
      |> Enum.reduce([], fn(segment, segments) ->
        case segment do
          "" -> segments
          _ -> List.insert_at(segments, -1, segment)
        end
      end)
      |> derive_schema(association, options)
  end

  defp derive_schema(segments, association, options) do
    resource = segments
      |> Enum.reduce(options.resource, fn(segment, resource) ->
        options
          |> MapUtils.get(:schema, %{})
          |> MapUtils.get(resource, %{})
          |> MapUtils.get(segment, %{})
          |> MapUtils.get(:resource, Inflex.pluralize(segment))
      end)

    defacto_schema(resource, association)
      |> MapUtils.deep_merge(MapUtils.get(options.schema, resource))
  end

  defp defacto_schema(resource, association \\ nil) do
    case association do
      nil -> %{}
      _ -> Dict.put(%{}, association, %{
        macro: derive_macro(association)
      })
    end
      |> Dict.put(:resource, resource)
      |> Dict.put(:table_name, resource)
  end

  defp derive_macro(association) do
    if Inflex.singularize(association) == association do
      :belongs_to
    else
      :has_many
    end
  end

  defp derive_table_joins(schema1, path, association, options) do
    schema2 = MapUtils.deep_merge(
      defacto_schema(Inflex.pluralize(association)),
      MapUtils.get(options.schema, association, %{})
    )

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
