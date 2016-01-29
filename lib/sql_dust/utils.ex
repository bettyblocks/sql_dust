defmodule SqlDust.Utils do

  def split_arguments(args) do
    String.split(args, ~r/, ?/)
  end

  def prepend_path_alias(arg, options) when arg == "*" do
    {arg, options}
  end

  def prepend_path_alias(arg, options) when is_list(arg) do
    Enum.reduce(arg, {[], options}, fn(sql, {paths, options}) ->
      {path, options} = prepend_path_alias(sql, options)
      {List.insert_at(paths, -1, path), options}
    end)
  end

  def prepend_path_alias(sql, options) do
    {path, column, options} = dissect_path(sql, options)
    path_alias = derive_path_alias(path, options)

    {"#{quote_alias(path_alias)}.#{column}", options}
  end

  def dissect_path(sql, options) do
    segments = String.split(sql, ".")
    path = Enum.slice(segments, 0..-2)
    column = List.last(segments)

    paths = Enum.concat(options[:paths], Enum.reduce(path, [], fn(segment, acc) ->
      path = []
        |> List.insert_at(-1, List.last(acc))
        |> List.insert_at(-1, segment)
        |> Enum.reject(fn(x) -> x == nil end)
        |> Enum.join(".")
      case path do
        "" -> acc
        _ -> List.insert_at(acc, -1, path)
      end
    end))

    {Enum.join(path, "."), column, Map.merge(options, %{paths: paths})}
  end

  def derive_path_alias(options) do
    derive_path_alias("", options)
  end

  def derive_path_alias(path, options) do
    case path do
      "" -> String.at(options.from, 0)
      _ -> path
    end
  end

  def quote_alias(sql) do
    "`#{sql}`"
  end

  def derive_join(path, options) do
    {prefix, association, options} = dissect_path(path, options)

    table = Inflex.pluralize(association)
    table_alias = quote_alias(derive_path_alias(path, options))
    prefix_alias = quote_alias(derive_path_alias(prefix, options))

    case derive_association_type(association) do
      :belongs_to ->
        %{
          table: "#{table} #{table_alias}",
          primary_key: "#{table_alias}.id",
          foreign_key: "#{prefix_alias}.#{association}_id",
        }
      :has_many ->
        if prefix == "" do
          association = Inflex.singularize(options.from)
        else
          {_, association, _} = dissect_path(prefix, options)
        end
        %{
          table: "#{table} #{table_alias}",
          primary_key: "#{table_alias}.#{association}_id",
          foreign_key: "#{prefix_alias}.id",
        }
    end
  end

  def derive_association_type(association) do
    if Inflex.singularize(association) == association do
      :belongs_to
    else
      :has_many
    end
  end
end
