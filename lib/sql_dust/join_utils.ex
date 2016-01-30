defmodule SqlDust.JoinUtils do
  import SqlDust.PathUtils

  def derive_join(path, options) do
    dissect_path(path, options)
      |> derive_tables(path)
      |> derive_keys(options)
      |> compose_sql
  end

  defp derive_tables({prefix, association, options}, path) do
    {
      association,
      %{
        table: Inflex.pluralize(association),
        prefix: prefix,
        table_alias: derive_quoted_path_alias(path, options),
        prefix_alias: derive_quoted_path_alias(prefix, options)
      }
    }
  end

  defp derive_keys({association, join}, options) do
    case derive_association_type(association) do
      :belongs_to -> derive_belongs_to_keys(association, join, options)
      :has_many -> derive_has_many_keys(association, join, options)
    end
      |> Map.merge(join)
  end

  defp derive_association_type(association) do
    if Inflex.singularize(association) == association do
      :belongs_to
    else
      :has_many
    end
  end

  defp derive_belongs_to_keys(association, join, _) do
    %{
      primary_key: "#{join.table_alias}.id",
      foreign_key: "#{join.prefix_alias}.#{association}_id",
    }
  end

  defp derive_has_many_keys(_, join, options) do
    association =
      if join.prefix == "" do
        Inflex.singularize(options.table)
      else
        dissect_path(join.prefix, options)
          |> Tuple.to_list
          |> List.at(1)
      end
    %{
      primary_key: "#{join.table_alias}.#{association}_id",
      foreign_key: "#{join.prefix_alias}.id",
    }
  end

  defp compose_sql(join) do
    "LEFT JOIN #{join.table} #{join.table_alias} ON #{join.primary_key} = #{join.foreign_key}"
  end
end
