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

  def derive_schema(segments, association, options) do
    resource = segments
      |> Enum.reduce(options.resource, fn(segment, resource) ->
        options
          |> MapUtils.get(:schema, %{})
          |> MapUtils.get(resource, %{})
          |> MapUtils.get(segment, %{})
          |> MapUtils.get(:resource, Inflex.pluralize(segment))
      end)

    defacto_schema(resource, association)
      |> MapUtils.deep_merge(MapUtils.get(options.schema, resource, %{}))
  end

  defp defacto_schema(resource, association) do
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
end
