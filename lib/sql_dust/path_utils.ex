defmodule SqlDust.PathUtils do
  import SqlDust.ScanUtils

  def prepend_path_aliases(sql, options) when sql == "*" do
    {sql, options}
  end

  def prepend_path_aliases(sql, options) when is_list(sql) do
    Enum.reduce(sql, {[], options}, fn(sql, {list, options}) ->
      {sql, options} = prepend_path_aliases(sql, options)
      {List.insert_at(list, -1, sql), options}
    end)
  end

  def prepend_path_aliases(sql, options) do
    excluded = []
      |> Enum.concat(scan_quoted(sql))
      |> Enum.concat(scan_functions(sql))
      |> Enum.concat(scan_aliases(sql))
      |> Enum.concat(scan_reserved_words(sql))
      |> List.flatten
      |> Enum.uniq

    sql = numerize_patterns(sql, excluded)
    {sql, options} = scan_and_prepend_path_aliases(sql, options)

    sql = interpolate_patterns(sql, excluded)
    {sql, options}
  end

  defp scan_and_prepend_path_aliases(sql, options) do
    regex = ~r/(?:\.\*|[a-zA-Z]\w+(?:\.(?:\*|\w{2,}))*)/

    paths = Regex.scan(regex, sql)
    sql = Regex.replace(regex, sql, fn(match) ->
      "{#{match}}"
    end)

    Enum.reduce(paths, {sql, options}, fn([path], {sql, options}) ->
      {path_alias, options} = prepend_path_alias(path, options, true)
      {String.replace(sql, "{#{path}}", path_alias), options}
    end)
  end

  def prepend_path_alias(path, options, cascade \\ false) do
    {path, column} = dissect_path(path)

    if cascade do
      paths = Enum.concat(options[:paths], cascaded_paths(path))
      options = Map.put(options, :paths, paths)
    end

    path_alias = derive_path_alias(path, options)

    {"#{quote_alias(path_alias)}.#{column}", options}
  end

  def dissect_path(path) do
    segments = String.split(path, ".")
    path = Enum.slice(segments, 0..-2)
    column = List.last(segments)

    {Enum.join(path, "."), column}
  end

  defp cascaded_paths(path) when is_bitstring(path) do
    cascaded_paths(String.split(path, "."))
  end

  defp cascaded_paths(path) do
    Enum.reduce(path, [], fn(segment, paths) ->
      path = []
        |> List.insert_at(-1, List.last(paths))
        |> List.insert_at(-1, segment)
        |> Enum.reject(fn(x) -> x == nil end)
        |> Enum.join(".")
      case path do
        "" -> paths
        _ -> List.insert_at(paths, -1, path)
      end
    end)
  end

  def derive_quoted_path_alias(path, options) do
    quote_alias derive_path_alias(path, options)
  end

  defp derive_path_alias(path, options) do
    case path do
      "" -> String.at(options.resource.name, 0)
      _ -> path
    end
  end

  defp quote_alias(sql) do
    "`#{sql}`"
  end
end
