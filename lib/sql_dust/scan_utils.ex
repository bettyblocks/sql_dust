defmodule SqlDust.ScanUtils do

  def scan_quoted(sql) do
    Regex.scan(~r/(["'])(?:(?=(\\?))\2.)*?\1/, sql)
      |> Enum.reduce([], fn([match, _, _], acc) ->
        case match do
          "" -> acc
          _ -> List.insert_at(acc, -1, match)
        end
      end)
  end

  def scan_functions(sql) do
    Regex.scan(~r/\b\w+\(/, sql)
  end

  def numerize_matches(sql, matches) do
    Enum.reduce(matches, sql, fn(match, acc) ->
      index = Enum.find_index(matches, fn(value) -> value == match end)
      String.replace(acc, match, "{#{index + 1}}")
    end)
  end

  def interpolate_matches(sql, matches) do
    Enum.reduce(matches, sql, fn(match, acc) ->
      index = Enum.find_index(matches, fn(value) -> value == match end)
      String.replace(acc, "{#{index + 1}}", match)
    end)
  end

end
