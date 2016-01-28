defmodule SqlDust do
  @moduledoc """
    SqlDust is a module that generates SQL queries as intuitively as possible.
  """

  @defaults %{select: ".*"}

  def from(table, options \\ %{}) do
    @defaults
      |> Map.merge(options)
      |> Map.merge(%{table: table})
      |> derive_select
      |> derive_from
      |> compose
  end

  defp derive_select(options) do
    select = []
      |> List.insert_at(-1, options[:select])
      |> List.flatten
      |> Enum.join(", ")
      |> String.split(", ")
      |> prepend_alias(options)
      |> Enum.join(", ")

    Dict.put options, :select, select
  end

  defp derive_from(options) do
    table_alias = ""
      |> path_alias(options)

    Dict.put options, :from, "#{options.table} #{table_alias}"
  end

  defp compose(options) do
    """
    SELECT #{options.select}
    FROM #{options.from}
    """
  end

  defp prepend_alias(arg, options) when is_list(arg) do
    arg
      |> Enum.map(fn(sql) -> prepend_alias(sql, options) end)
  end

  defp prepend_alias(sql, options) do
    "#{path_alias(sql, options)}.#{List.last(String.split(sql, "."))}"
  end

  defp path_alias(path, options) do
    sql = path
      |> String.split(".")
      |> Enum.slice(0..-2)
      |> Enum.join(".")

    if sql == "" do
      sql = String.at(options.table, 0)
    end

    quote_alias sql
  end

  defp quote_alias(sql) do
    "`#{sql}`"
  end
end
