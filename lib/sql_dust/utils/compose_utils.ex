defmodule SqlDust.ComposeUtils do
  alias SqlDust.MapUtils

  defmacro __using__(_) do
    quote do
      def select(args)                 do select(options, args) end
      def select(options, args)        do append(options, :select, args) end

      def from(resource)               do from(options, resource) end
      def from(options, resource)      do __from__(options, resource) end
      defp __from__(options, resource) do put(options, :from, resource) end

      def where(statements)            do where(options, statements) end
      def where(options, statements)   do append(options, :where, statements) end

      def group_by(args)               do group_by(options, args) end
      def group_by(options, args)      do append(options, :group_by, args) end

      def order_by(args)               do order_by(options, args) end
      def order_by(options, args)      do append(options, :order_by, args) end

      def limit(resource)              do limit(options, resource) end
      def limit(options, resource)     do put(options, :limit, resource) end

      def offset(resource)              do offset(options, resource) end
      def offset(options, resource)     do put(options, :offset, resource) end

      def adapter(name)                do adapter(options, name) end
      def adapter(options, name)       do put(options, :adapter, name) end

      def schema(map)                  do schema(options, map) end
      def schema(options, map)         do merge(options, :schema, map) end

      defp parse(options)              do __parse__(options) end

      defp __parse__(options) do
        if is_bitstring(options) do
          from(options)
        else
          options
        end
      end

      def to_sql(options) do
        options = parse(options)

        if (is_nil(options.from)) do;
          raise "missing :from option in query dust"
        end

        from = options.from
        schema = options.schema
        options = Map.take(options, [:select, :where, :group_by, :order_by, :limit, :offset, :adapter])
                  |> Enum.reduce(%{from: options.from}, fn({key, value}, map) ->
                    if is_nil(value) do
                      map
                    else
                      Map.put(map, key, value)
                    end
                  end)

        SqlDust.from(from, options, schema || %{})
      end

      defp options do
        %SqlDust{}
      end

      defp put(options, key, value) do
        Map.put(parse(options), key, value)
      end

      defp append(options, key, value) do
        options = parse(options)
        value = (Map.get(options, key) || [])
          |> Enum.concat(
            [value] |> List.flatten
          )

        Map.put options, key, value
      end

      defp merge(options, key, value) do
        options = parse(options)
        value = (Map.get(options, key) || %{})
          |> MapUtils.deep_merge(value)

        Map.put options, key, value
      end

      defoverridable [from: 2, parse: 1]
    end
  end
end
