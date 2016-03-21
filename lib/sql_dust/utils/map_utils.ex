defmodule SqlDust.MapUtils do
  def get(map, key, default \\ nil) do
    key = "#{key}"
    Map.get(map, key, Map.get(map, String.to_atom(key), default))
  end

  def deep_merge(map1, map2) do
    Map.keys(map1)
      |> Enum.concat(Map.keys(map2))
      |> Enum.join(";")
      |> String.split(";")
      |> Enum.reduce(%{}, fn(key, map) ->
        {val1, val2} = {get(map1, key), get(map2, key)}
        val = cond do
          is_map(val1) -> deep_merge(val1, val2 || %{})
          Map.has_key?(map2, String.to_atom(key)) -> val2
          true -> val1
        end
        Map.put(map, String.to_atom(key), val)
      end)
  end
end
