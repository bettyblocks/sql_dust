defmodule SqlDust.PathUtils do
  import SqlDust.ScanUtils

  def prepend_path_aliases(sql, options) when sql == "*" do
    {sql, options}
  end

  def prepend_path_aliases(sql, options) do
    excluded = []
      |> Enum.concat(scan_quoted(sql))
      |> Enum.concat(scan_functions(sql))
      |> List.flatten
      |> Enum.uniq

    sql = numerize_matches(sql, excluded)
    {sql, options} = scan_and_prepend_path_aliases(sql, options)

    sql = interpolate_matches(sql, excluded)
    {sql, options}
  end

  defp scan_and_prepend_path_aliases(sql, options) do
    regex = ~r/(?:\.\*|[a-zA-Z]\w+(?:\.\w{2,})*)/

    paths = Regex.scan(regex, sql)
    sql = Regex.replace(regex, sql, fn(match) ->
      "{#{match}}"
    end)

    Enum.reduce(paths, {sql, options}, fn([path], {acc, options}) ->
      {path_alias, options} = prepend_path_alias(path, options)
      {String.replace(acc, "{#{path}}", path_alias), options}
    end)
  end

  defp prepend_path_alias(sql, options) do
    {path, column, options} = dissect_path(sql, options)
    path_alias = derive_path_alias(path, options)

    {"#{quote_alias(path_alias)}.#{column}", options}
  end

  def dissect_path(sql, options \\ %{paths: []}) do
    segments = String.split(sql, ".")
    path = Enum.slice(segments, 0..-2)
    column = List.last(segments)
    paths = Enum.concat(options[:paths], cascaded_paths(path))

    {Enum.join(path, "."), column, Dict.put(options, :paths, paths)}
  end

  defp cascaded_paths(path) do
    Enum.reduce(path, [], fn(segment, acc) ->
      path = []
        |> List.insert_at(-1, List.last(acc))
        |> List.insert_at(-1, segment)
        |> Enum.reject(fn(x) -> x == nil end)
        |> Enum.join(".")
      case path do
        "" -> acc
        _ -> List.insert_at(acc, -1, path)
      end
    end)
  end

  def derive_quoted_path_alias(path, options) do
    quote_alias derive_path_alias(path, options)
  end

  defp derive_path_alias(path, options) do
    case path do
      "" -> String.at(options.resource, 0)
      _ -> path
    end
  end

  defp quote_alias(sql) do
    "`#{sql}`"
  end
end
