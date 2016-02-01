defmodule SqlDust.SchemaUtils do
  alias SqlDust.MapUtils, as: MapUtils

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
    defacto_schema(resource, association)
      |> MapUtils.deep_merge(
        MapUtils.get(options.schema, resource, %{})
      )
  end

  defp defacto_schema(resource, association) do
    %{
      name: resource,
      table_name: resource
    }
      |> Map.merge(defacto_association(resource, association))
  end

  defp defacto_association(_, association) when is_nil(association), do: %{}

  defp defacto_association(resource, association) do
    macro = derive_macro(association)

    map = case macro do
      :belongs_to -> %{
        primary_key: "id",
        foreign_key: "#{association}_id"
      }
      :has_many -> %{
        primary_key: "#{Inflex.singularize(resource)}_id",
        foreign_key: "id"
      }
    end
      |> Map.put(:macro, macro)

    %{}
      |> Map.put(association, map)
  end

  defp derive_macro(association) do
    if Inflex.singularize(association) == association do
      :belongs_to
    else
      :has_many
    end
  end
end
