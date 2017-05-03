defmodule SqlDust.QueryUtils do
  defmacro __using__(_) do
    quote do
      use SqlDust.ComposeUtils

      def to_sql(options) do
        options = parse(options)

        if (is_nil(options.from)) do;
          raise "missing :from option in query dust"
        end

        from = options.from
        schema = options.schema
        options = Map.take(options, [:select, :join_on, :where, :group_by, :order_by, :limit, :offset, :unique, :variables, :adapter])
                  |> Enum.reduce(%{from: options.from}, fn
                    ({_key,  nil}, map) -> map
                    ({key, value}, map) -> Map.put(map, key, value)
                  end)

        SqlDust.from(from, options, schema || %{})
      end

    end
  end
end
