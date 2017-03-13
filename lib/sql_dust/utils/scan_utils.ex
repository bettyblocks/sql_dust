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

  def scan_existing_alias(sql) do
    Regex.scan(~r/ AS \".+\"/i, sql)
  end

  def scan_variables(sql) do
    Regex.scan(~r/<<[\w\.]+>>/, sql)
  end

  def scan_parenthesized(sql) do
    Regex.scan(~r/\([^\(\)]*?\)/, sql)
  end

  def scan_functions(sql) do
    Regex.scan(~r/\b\w+\(/, sql)
  end

  def scan_aliases(sql) do
    Regex.scan(~r/ AS .+?(?=\)|$)/i, sql)
  end

  def scan_reserved_words(sql) do
    Regex.scan(~r/\b(distinct|and|as|or|is|like|rlike|point|bigint|bigserial|bit|bit|varying|boolean|bytea|character|character|varying|date|double|precision|integer|numeric|real|serial|smallint|text|time|with|timezone|timestamp|with|timezone|xml|regexp|in|interval|between|not|null|sounds|soundex|asc|desc|true|false)\b/i, sql)
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
        if Regex.match?(~r/^\w+$/, pattern) do
          {_, regex} = Regex.compile("(^|\\b)" <> pattern <> "(\\b|$)")
          Regex.replace(regex, sql, fn(_, prefix, postfix) ->
            "#{prefix}{#{index + 1}}#{postfix}"
          end)
        else
          String.replace(sql, pattern, "{#{index + 1}}")
        end
      end
    end)
  end

  def interpolate_patterns(sql, patterns) do
    Enum.reduce(patterns, sql, fn(pattern, sql) ->
      index = Enum.find_index(patterns, fn(value) -> value == pattern end)
      pattern = if is_list(pattern), do: Enum.at(pattern, 1), else: pattern
      String.replace(sql, "{#{index + 1}}", pattern)
    end)
  end

  def interpolate_variables(sql, variables, initial_variables) do
    excluded = scan_quoted(sql)
    sql = numerize_patterns(sql, excluded)

    {sql, values, keys} = Regex.scan(~r/<<([\w\.]+)>>/, sql)
                          |> Enum.reduce({sql, [], []}, fn([match, key], {sql, values, keys}) ->
                            value = String.split(key, ".") |> Enum.reduce(variables, fn(name, variables) ->
                              MapUtils.get(variables, name)
                            end)

                            anonymous_key = Regex.match?(~r(__\d+__), key) || (
                              String.contains?(key, "_options_") && (
                                !(initial_variables
                                  |> MapUtils.get(:_options_, %{})
                                  |> Map.keys
                                  |> Enum.map(fn(k) ->
                                       if is_atom(k), do: Atom.to_string(k), else: k
                                     end)
                                  |> Enum.member?(String.split(key, ".") |> Enum.at(1)))
                              )
                            )

                            sql = String.replace sql, match, "?", global: false
                            values = [value] ++ values
                            key = if anonymous_key, do: nil, else: key
                            keys = [key] ++ keys

                            {sql, values, keys}
                          end)

    values = Enum.reverse(values)
    keys = Enum.reverse(keys)

    sql = interpolate_patterns(sql, excluded)
    include_keys = Enum.any?(Map.keys(initial_variables), fn(key) ->
                     key = if is_atom(key), do: Atom.to_string(key), else: key
                     !Regex.match?(~r(__\d+__), key)
                   end)

    if include_keys do
      {sql, values, keys}
    else
      {sql, values}
    end
  end
end
