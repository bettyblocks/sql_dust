defmodule SqlDust.ScanUtils do
  def split_arguments(sql) do
    excluded = scan_quoted(sql)

    {sql, excluded} = numerize_patterns(sql, excluded)
      |> numerize_parenthesized(excluded)

    {list, _} = sql
      |> String.split(~r/\s*,\s*/)
      |> Enum.reduce({[], excluded}, fn(sql, {list, excluded}) ->
        sql = interpolate_parenthesized(sql, excluded)
        {List.insert_at(list, -1, sql), excluded}
      end)

    list
  end

  defp numerize_parenthesized(sql, patterns) do
    parenthesized = scan_parenthesized(sql)

    if length(parenthesized) == 0 do
      {sql, patterns}
    else
      patterns = patterns
        |> Enum.concat(parenthesized)
        |> List.flatten
        |> Enum.uniq
      numerize_patterns(sql, patterns)
        |> numerize_parenthesized(patterns)
    end
  end

  defp interpolate_parenthesized(sql, patterns) do
    if String.match?(sql, ~r/\{\d+\}/) do
      interpolate_patterns(sql, patterns)
        |> interpolate_parenthesized(patterns)
    else
      sql
    end
  end

  def scan_quoted(sql) do
    Regex.scan(~r/(["'])(?:(?=(\\?))\2.)*?\1/, sql)
      |> Enum.reduce([], fn([match, _, _], quoted) ->
        case match do
          "" -> quoted
          _ -> List.insert_at(quoted, -1, match)
        end
      end)
  end

  def scan_parenthesized(sql) do
    Regex.scan(~r/\([^\(\)]*?\)/, sql)
  end

  def scan_functions(sql) do
    Regex.scan(~r/\b\w+\(/, sql)
  end

  def scan_aliases(sql) do
    Regex.scan(~r/ AS \w+$/i, sql)
  end

  def scan_reserved_words(sql) do
    Regex.scan(~r/\b(asc|desc)\b/i, sql)
  end

  def numerize_patterns(sql, patterns) do
    Enum.reduce(patterns, sql, fn(pattern, sql) ->
      index = Enum.find_index(patterns, fn(value) -> value == pattern end)
      String.replace(sql, pattern, "{#{index + 1}}")
    end)
  end

  def interpolate_patterns(sql, patterns) do
    Enum.reduce(patterns, sql, fn(pattern, sql) ->
      index = Enum.find_index(patterns, fn(value) -> value == pattern end)
      String.replace(sql, "{#{index + 1}}", pattern)
    end)
  end
end
