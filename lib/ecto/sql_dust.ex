defmodule Ecto.SqlDust do
  use SqlDust.ComposeUtils

  def from(options, model) do
    resource = model.__schema__(:source)
    derived_schema = derive_schema(model)

    options
      |> __from__(resource)
      |> adapter(:postgres)
      |> schema(derived_schema)
  end

  defp parse(options) do
    try do
      case options.__struct__ do
        SqlDust -> options
        _ -> from(options)
      end
    catch
      _ -> __parse__(options)
    end
  end

  defp derive_schema(model) do
    derive_schema(%{}, model)
  end

  defp derive_schema(schema, model) do
    source = model.__schema__(:source)
    associations = model.__schema__(:associations)

    schema = schema
      |> Map.put(source, Enum.reduce(associations, %{name: source, table_name: source}, fn(association, map) ->
        reflection = model.__schema__(:association, association)
        Map.put(map, association, derive_association(reflection))
      end))

    schema = associations
      |> Enum.map(fn(association) ->
        model.__schema__(:association, association).queryable
      end)
      |> Enum.uniq
      |> Enum.reduce(schema, fn(model, schema) ->
        model_source = model.__schema__(:source)
        if (source == model_source) || Map.has_key?(schema, model_source) do
          schema
        else
          derive_schema(schema, model)
        end
      end)

    schema
  end

  defp derive_association(reflection) do
    macro = case reflection.__struct__ do
      Ecto.Association.BelongsTo -> :belongs_to
      Ecto.Association.Has ->
        case reflection.cardinality do
          :one -> :has_one
          :many -> :has_many
        end
      Ecto.Association.ManyToMany -> :has_and_belongs_to_many
    end

    Map.merge(%{
      macro: macro,
      resource: reflection.related.__schema__(:source)
    }, derive_association(macro, reflection))
  end

  defp derive_association(macro, reflection) when macro == :belongs_to do
    %{
      primary_key: Atom.to_string(reflection.related_key),
      foreign_key: Atom.to_string(reflection.owner_key)
    }
  end

  defp derive_association(macro, reflection) when macro == :has_one do
    %{
      primary_key: Atom.to_string(reflection.owner_key),
      foreign_key: Atom.to_string(reflection.related_key)
    }
  end

  defp derive_association(macro, reflection) when macro == :has_many do
    %{
      primary_key: Atom.to_string(reflection.owner_key),
      foreign_key: Atom.to_string(reflection.related_key)
    }
  end

  # ???
  # defp derive_association(macro, reflection) when macro == :has_and_belongs_to_many do
  #   %{
  #     # bridge_table: ([Inflex.pluralize(resource), Inflex.pluralize(association)] |> Enum.sort |> Enum.join("_")),
  #     # primary_key: "id",
  #     # foreign_key: "#{Inflex.singularize(resource)}_id",
  #     # association_primary_key: "id",
  #     # association_foreign_key: "#{Inflex.singularize(association)}_id"
  #   }
  # end
end
