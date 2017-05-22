defmodule SqlDust.PathUtils do
  @moduledoc false
  import SqlDust.ScanUtils

  def prepend_path_aliases([], options), do: {[], options}
  def prepend_path_aliases([sql_line | sql_lines], options) do
    {prepedend_sql_line, prepended_options} = prepend_path_aliases(sql_line, options)
    {prepedend_sql_lines, acc_prepended_options} = prepend_path_aliases(sql_lines, prepended_options)

    {[prepedend_sql_line | prepedend_sql_lines], acc_prepended_options}
  end
  def prepend_path_aliases(sql, options) when sql == "*", do: {sql, options}
  def prepend_path_aliases(sql, options) when is_binary(sql) do
    {sql, aliases, excluded} = scan_and_format_aliases(sql, options)
    {sql, dust_paths} = scan_and_replace_dust_paths(sql)
    options = Map.put(options, :aliases, aliases)
    {sql, options} =
      sql
      |> numerize_patterns(excluded)
      |> restore_dust_paths(dust_paths)
      |> scan_and_prepend_path_aliases(options)

    sql = interpolate_patterns(sql, excluded)
    {sql, options}
  end

  defp scan_and_replace_dust_paths(sql) do
    path_regex = ~r/\[([\w\d\._]+)\]/i
    dust_paths = Regex.scan(path_regex, sql) |> Enum.map( &List.first(&1) )
    {sql, _} = Enum.reduce(dust_paths, {sql, 0}, fn(path, {sql, index}) ->
                 index_str = "[#{index}]"
                 {String.replace(sql, path, index_str), index + 1}
               end)

    {sql, dust_paths}
  end
  defp restore_dust_paths(sql, []), do: sql
  defp restore_dust_paths(sql, dust_paths) do
    (0..length(dust_paths) - 1)
    |> Enum.reduce(sql, fn(index, sql) ->
         search_string = "[#{index}]"
         replace_string = Enum.at(dust_paths, index) |> String.slice(1..-2)
         String.replace(sql, search_string, replace_string)
       end)
  end

  defp scan_and_format_aliases(sql, options) when is_binary(sql) do
    {excluded, aliases} = scan_excluded(sql)

    aliases =
      aliases
      |> Enum.map(&fix_sql_alias/1)
      |> Enum.concat(options.aliases)
      |> Enum.uniq

    excluded = format_excluded_aliases(excluded, aliases, options)

    {sql, aliases, excluded}
  end

  defp format_excluded_aliases(excluded, aliases, options) do
    excluded
    |> Enum.map(fn(excluded) ->
         if match_excluded_alias(excluded) do
           {_, compiled} = Regex.compile(excluded)

           [compiled, " AS " <> quote_alias(fix_sql_alias(excluded), options)]
         else
           excluded
         end
       end)
    |> Enum.concat(
         Enum.map(aliases, fn(sql_alias) ->
           [~r/([^\.\w])#{sql_alias}([^\.\w])/, quote_alias(sql_alias, options)]
         end)
       )
  end

  defp fix_sql_alias(" AS " <> sql_alias), do: sql_alias
  defp fix_sql_alias(" as " <> sql_alias), do: sql_alias
  defp fix_sql_alias(sql_alias), do: sql_alias

  defp match_excluded_alias(" AS "), do: false
  defp match_excluded_alias(" as "), do: false
  defp match_excluded_alias(" AS " <> _), do: true
  defp match_excluded_alias(" as " <> _), do: true
  defp match_excluded_alias(_sql_alias), do: false

  def sanitize_sql(sql) do
    {excluded, _} = scan_excluded(sql)
    Enum.reduce(excluded, sql, fn(pattern, sql) ->
      String.replace(sql, pattern, "")
    end)
  end

  def scan_excluded(sql) do
    excluded = []
      |> Enum.concat(scan_strings(sql))
      |> Enum.concat(scan_variables(sql))
      |> Enum.concat(scan_functions(sql))
      |> Enum.concat(aliases = (sql |> scan_aliases() |> List.flatten |> Enum.uniq))
      |> Enum.concat(scan_reserved_words(sql))
      |> List.flatten
      |> Enum.uniq

    {excluded, aliases}
  end

  defp scan_and_prepend_path_aliases(sql, options) do
    ~r/(?:\.\*|\w+[a-zA-Z]+\w*(?:\.(?:\*|\w{2,}))*)/
    |> Regex.split(sql, [include_captures: true])
    |> analyze_aliases([], options, false)
  end

  defp analyze_aliases([h], out, options, false) do
    {[h | out] |> Enum.reverse() |> Enum.join(""), options}
  end
  defp analyze_aliases([path], out, options, true) do
    {path_alias, options} = prepend_path_alias(path, options, true)
    analyze_aliases([path_alias], out, options, false)
  end
  defp analyze_aliases([h | t], out, options, false) do
    analyze_aliases(t, [h | out], options, true)
  end
  defp analyze_aliases([path | rest], out, options, true) do
    {path_alias, options} = prepend_path_alias(path, options, true)
    analyze_aliases(rest, [path_alias | out], options, false)
  end

  def prepend_path_alias(path, options, cascade \\ false) do
    {path, column} = do_dissect_path(path, options)

    options =
      if cascade do
        paths = Enum.concat(options[:paths], cascaded_paths(path))
        Map.put(options, :paths, paths)
      else
        options
      end

    path_alias = derive_path_alias(path, options)

    {quote_alias(path_alias, options) <> "." <> quote_alias(column, options), options}
  end

  def dissect_path(path, options) do
    {path, column} = do_dissect_path(path, options)
    {Enum.join(path, "."), column}
  end

  defp do_dissect_path(path, options) do

    quotation_symbol = quotation_mark(options)
    split_on_dot_outside_quotation_mark = ~r/\.(?=(?:[^#{quotation_symbol}]*#{quotation_symbol}[^#{quotation_symbol}]*#{quotation_symbol})*[^#{quotation_symbol}]*$)/
    segments = String.split(path, split_on_dot_outside_quotation_mark)

    case Enum.split(segments, -1) do
      {prefix, [last]} -> {prefix, last}
      {[], []} -> {[], nil}
    end
  end

  defp cascaded_paths(path) when is_bitstring(path) do
    cascaded_paths(String.split(path, "."))
  end

  defp cascaded_paths(path) do
    path
    |> Enum.reduce([], fn
      (segment, paths) when segment in [nil, ""] -> paths
      (segment, []) -> [segment]
      (segment, [h | _] = paths) -> [h <> "." <> segment | paths]
    end)
    |> Enum.reverse()
  end

  def derive_quoted_path_alias(path, options) do
    quote_alias(derive_path_alias(path, options), options)
  end

  defp derive_path_alias(path, options) when is_list(path) do
    derive_path_alias(Enum.join(path, "."), options)
  end

  defp derive_path_alias(path, options) do
    case String.replace(path, quotation_mark(options), "") do
      "" -> String.downcase(String.at(options.resource.name, 0))
      _ -> path
    end
  end

  def quotation_mark(%{adapter: :mysql}) do
    "`"
  end

  def quotation_mark(_) do
    "\""
  end

  def quote_alias("*" = sql, _) do
    sql
  end

  def quote_alias(sql, options) do
    quotation_symbol = quotation_mark(options)
    if Regex.match?(~r/\A#{quotation_symbol}.*#{quotation_symbol}\z/, sql) do
      sql
    else
      quotation_symbol <> sql <> quotation_symbol
    end
  end
end
