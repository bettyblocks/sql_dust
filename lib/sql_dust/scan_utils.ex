defmodule SqlDust.ScanUtils do
  def scan_quoted(sql) do
    Regex.scan(~r/(["'])(?:(?=(\\?))\2.)*?\1/, sql)
      |> Enum.reduce([], fn([match, _, _], quoted) ->
        case match do
          "" -> quoted
          _ -> List.insert_at(quoted, -1, match)
        end
      end)
  end

  def scan_functions(sql) do
    Regex.scan(~r/\b\w+\(/, sql)
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
