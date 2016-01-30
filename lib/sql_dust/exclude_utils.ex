defmodule SqlDust.ExcludeUtils do

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

  def numerize_excluded(sql, excluded) do
    Enum.reduce(excluded, sql, fn(match, acc) ->
      index = Enum.find_index(excluded, fn(value) -> value == match end)
      String.replace(acc, match, "{#{index + 1}}")
    end)
  end

  def interpolate_excluded(sql, excluded) do
    Enum.reduce(excluded, sql, fn(match, acc) ->
      index = Enum.find_index(excluded, fn(value) -> value == match end)
      String.replace(acc, "{#{index + 1}}", match)
    end)
  end

end
