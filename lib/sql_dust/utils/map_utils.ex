defmodule SqlDust.MapUtils do
  def get(map, key, default \\ nil) do
    key = "#{key}"
    Map.get(map, key, Map.get(map, String.to_atom(key), default))
  end

  def deep_merge(map1, map2) do
    Map.keys(map1)
      |> Enum.concat(Map.keys(map2))
      |> Enum.map(&stringify_key/1)
      |> Enum.reduce(%{}, fn(key, map) ->
        {val1, val2} = {get(map1, key), get(map2, key)}
        val = cond do
          is_map(val1) -> deep_merge(val1, val2 || %{})
          has_key?(map2, key) -> val2
          true -> val1
        end
        Map.put(map, String.to_atom(key), val)
      end)
  end

  defp has_key?(map, key) do
    Map.has_key?(map, key) || Map.has_key?(map, String.to_atom(key))
  end

  defp stringify_key(key) when is_bitstring(key), do: key
  defp stringify_key(key), do: to_string(key)
end
