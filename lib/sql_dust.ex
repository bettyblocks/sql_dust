defmodule SqlDust do
  import SqlDust.Utils

  @moduledoc """
    SqlDust is a module that generates SQL queries as intuitively as possible.
  """

  def from(table, options \\ %{}) do
    %{select: ".*", table: table, paths: []}
      |> Map.merge(options)
      |> derive_select
      |> derive_from
      |> compose
  end

  defp derive_select(options) do
    select = []
      |> List.insert_at(-1, options[:select])
      |> List.flatten
      |> Enum.join(", ")
      |> split_arguments
      |> prepend_alias(options)

    Dict.put options, :select, select
  end

  defp derive_from(options) do
    table_alias = ""
      |> path_alias(options)

    Dict.put options, :from, "#{options.table} #{table_alias}"
  end

  defp compose(options) do
    select = Enum.join(options.select, ", ")
    from = options.from
    """
    SELECT #{select}
    FROM #{from}
    """
  end
end
