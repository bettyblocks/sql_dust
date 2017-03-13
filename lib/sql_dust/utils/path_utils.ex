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
    {excluded, aliases} = scan_excluded(sql)

    aliases = aliases
      |> Enum.map(fn(sql_alias) ->
        String.replace(sql_alias, ~r/^ AS /i, "")
      end)
      |> Enum.concat(options.aliases)
      |> Enum.uniq

    excluded = excluded
      |> Enum.map(fn(excluded) ->
        regex = ~r/^( AS )(.+)/i
        if Regex.match?(regex, excluded) do
          {_, compiled} = Regex.compile(excluded)
          [compiled, Regex.replace(regex, excluded, fn(_, as, path) ->
            as <> quote_alias(path, options)
          end)]
        else
          excluded
        end
      end)
      |> Enum.concat(Enum.map(aliases, fn(sql_alias) ->
        [~r/([^\.\w])#{sql_alias}([^\.\w])/, quote_alias(sql_alias, options)]
      end))
    options = Map.put(options, :aliases, aliases)

    sql = numerize_patterns(sql, excluded)
    {sql, options} = scan_and_prepend_path_aliases(sql, options)

    sql = interpolate_patterns(sql, excluded)
    {sql, options}
  end

  def sanitize_sql(sql) do
    {excluded, _} = scan_excluded(sql)
    Enum.reduce(excluded, sql, fn(pattern, sql) ->
      String.replace(sql, pattern, "")
    end)
  end

  def scan_excluded(sql) do
    excluded = []
      |> Enum.concat(scan_quoted(sql))
      |> Enum.concat(scan_variables(sql))
      |> Enum.concat(scan_functions(sql))
      |> Enum.concat(scan_reserved_words(sql))
      |> Enum.concat(aliases = scan_aliases(sql) |> List.flatten |> Enum.uniq)
      |> List.flatten
      |> Enum.uniq
      |> IO.inspect

    {excluded, aliases}
  end

  defp scan_and_prepend_path_aliases(sql, options) do
    regex = ~r/(?:\.\*|\w+[a-zA-Z]+\w*(?:\.(?:\*|\w{2,}))*)/

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
    {path, column} = dissect_path(path, options)

    options =
      if cascade do
        paths = Enum.concat(options[:paths], cascaded_paths(path))
        Map.put(options, :paths, paths)
      else
        options
      end

    path_alias = derive_path_alias(path, options)

    {"#{quote_alias(path_alias, options)}.#{quote_alias(column, options)}", options}
  end

  def dissect_path(path, options) do
    quotation_mark = quotation_mark(options)
    split_on_dot_outside_quotation_mark = ~r/\.(?=(?:[^#{quotation_mark}]*#{quotation_mark}[^#{quotation_mark}]*#{quotation_mark})*[^#{quotation_mark}]*$)/
    segments = String.split(path, split_on_dot_outside_quotation_mark)
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
    quote_alias(derive_path_alias(path, options), options)
  end

  defp derive_path_alias(path, options) do
    case String.replace(path, "#{quotation_mark(options)}", "") do
      "" -> String.downcase(String.at(options.resource.name, 0))
      _ -> path
    end
  end

  def quotation_mark(%{adapter: :mysql}) do
    "`"
  end

  def quotation_mark(_) do
    '"'
  end

  def quote_alias("*" = sql, _) do
    sql
  end

  def quote_alias(sql, options) do
    quotation_mark = quotation_mark(options)
    if Regex.match?(~r/\A#{quotation_mark}.*#{quotation_mark}\z/, sql) do
      sql
    else
      "#{quotation_mark}#{sql}#{quotation_mark}"
    end
  end
end
