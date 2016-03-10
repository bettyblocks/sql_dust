defmodule SqlDust.SchemaUtils do
  alias SqlDust.MapUtils

  def derive_schema(path, association, options) when is_bitstring(path) do
    String.split(path, ".")
      |> Enum.reduce([], fn(segment, segments) ->
        case segment do
          "" -> segments
          _ -> List.insert_at(segments, -1, segment)
        end
      end)
      |> derive_schema(association, options)
  end

  def derive_schema(path, association, options) do
    path
      |> Enum.reduce(options.resource.name, fn(path_segment, resource) ->
        options
          |> MapUtils.get(:schema, %{})
          |> MapUtils.get(resource, %{})
          |> MapUtils.get(path_segment, %{})
          |> MapUtils.get(:resource, Inflex.pluralize(path_segment))
      end)
      |> resource_schema(association, options)
  end

  def resource_schema(resource, options) do
    resource_schema(resource, nil, options)
  end

  def resource_schema(resource, association, options) do
    schema = MapUtils.get(options.schema, resource, %{})
    cardinality = MapUtils.get(MapUtils.get(schema, association, %{}), :cardinality)

    defacto_schema(resource)
      |> Map.merge(defacto_association(resource, association, cardinality))
      |> MapUtils.deep_merge(schema)
  end

  defp defacto_schema(resource) do
    %{
      name: resource,
      table_name: resource
    }
  end

  defp defacto_association(_, association, _) when is_nil(association), do: %{}

  defp defacto_association(resource, association, cardinality) do
    cardinality = cardinality || derive_cardinality(association)

    map = case cardinality do
      :belongs_to -> %{
        primary_key: "id",
        foreign_key: "#{association}_id"
      }
      :has_one -> %{
        primary_key: "id",
        foreign_key: "#{Inflex.singularize(resource)}_id"
      }
      :has_many -> %{
        primary_key: "id",
        foreign_key: "#{Inflex.singularize(resource)}_id"
      }
      :has_and_belongs_to_many -> %{
        bridge_table: ([Inflex.pluralize(resource), Inflex.pluralize(association)] |> Enum.sort |> Enum.join("_")),
        primary_key: "id",
        foreign_key: "#{Inflex.singularize(resource)}_id",
        association_primary_key: "id",
        association_foreign_key: "#{Inflex.singularize(association)}_id"
      }
    end
      |> Map.put(:cardinality, cardinality)

    %{}
      |> Map.put(association, map)
  end

  defp derive_cardinality(association) do
    if Inflex.singularize(association) == association do
      :belongs_to
    else
      :has_many
    end
  end
end
