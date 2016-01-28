defmodule SqlDust.Utils do

  def split_arguments(args) do
    String.split(args, ", ")
  end

  def prepend_alias(arg, options) when is_list(arg) do
    Enum.map(arg, fn(sql) -> prepend_alias(sql, options) end)
  end

  def prepend_alias(sql, _) when sql == "*" do
    sql
  end

  def prepend_alias(sql, options) do
    path = path_alias(sql, options)
    column = List.last(String.split(sql, "."))

    "#{path}.#{column}"
  end

  def path_alias(path, options) do
    sql = path
      |> String.split(".")
      |> Enum.slice(0..-2)
      |> Enum.join(".")

    if sql == "" do
      sql = String.at(options.table, 0)
    end

    quote_alias sql
  end

  def quote_alias(sql) do
    "`#{sql}`"
  end
end
