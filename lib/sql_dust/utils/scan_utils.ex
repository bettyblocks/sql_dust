defmodule SqlDust.ScanUtils do
  alias SqlDust.MapUtils

  def split_arguments(sql) when is_list(sql) do
    sql
      |> List.flatten
      |> Enum.join(", ")
      |> split_arguments
  end

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
      |> Enum.reduce([], fn(match, quoted) ->
        match = hd(match)
        case match do
          "" -> quoted
          _ -> List.insert_at(quoted, -1, match)
        end
      end)
  end

  def scan_variables(sql) do
    Regex.scan(~r/<<\w+>>/, sql)
  end

  def scan_parenthesized(sql) do
    Regex.scan(~r/\([^\(\)]*?\)/, sql)
  end

  def scan_functions(sql) do
    Regex.scan(~r/\b\w+\(/, sql)
  end

  def scan_aliases(sql) do
    Regex.scan(~r/ AS .+$/i, sql)
  end

  def scan_reserved_words(sql) do
    Regex.scan(~r/\b(distinct|and|or|is|like|rlike|regexp|in|between|not|null|sounds|soundex|asc|desc|true|false)\b/i, sql)
  end

  def numerize_patterns(sql, patterns) do
    Enum.reduce(patterns, sql, fn(pattern, sql) ->
      index = Enum.find_index(patterns, fn(value) -> value == pattern end)
      if is_list(pattern) do
        regex = Enum.at(pattern, 0)
        Regex.replace(regex, sql, fn(_, prefix, postfix) ->
          "#{prefix}{#{index + 1}}#{postfix}"
        end)
      else
        String.replace(sql, pattern, "{#{index + 1}}")
      end
    end)
  end

  def interpolate_patterns(sql, patterns) do
    Enum.reduce(patterns, sql, fn(pattern, sql) ->
      index = Enum.find_index(patterns, fn(value) -> value == pattern end)
      if is_list(pattern) do
        pattern = Enum.at(pattern, 1)
      end
      String.replace(sql, "{#{index + 1}}", pattern)
    end)
  end

  def process_variables(sql, variables) do
    excluded = scan_quoted(sql)
    sql = numerize_patterns(sql, excluded)

    {sql, values} = Regex.scan(~r/<<(\w+)>>/, sql)
                    |> Enum.reduce({sql, []}, fn([match, name], {sql, values}) ->
                      values = values |> List.insert_at(-1, MapUtils.get(variables, name))
                      sql = String.replace sql, match, "?", global: false
                      {sql, values}
                    end)

    {interpolate_patterns(sql, excluded), values}
  end
end
