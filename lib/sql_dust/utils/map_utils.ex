defmodule SqlDust.MapUtils do
  def get(map, key, default \\ nil)
  def get(map, key, default) when is_atom(key) do
    Map.get(map, key, Map.get(map, Atom.to_string(key), default))
  end
  def get(map, key, default) when is_bitstring(key) do
    Map.get(map, key, Map.get(map, String.to_atom(key), default))
  end
  def get(map, key, default), do: get(map, to_string(key), default)

  def deep_merge(map1, map2) do
    Map.keys(map1)
      |> Enum.concat(Map.keys(map2))
      |> Enum.reduce(%{}, fn
        (key, map) when is_atom(key) ->
          val = proceed_key(key, map1, map2)
          Map.put(map, key, val)
        (key, map) ->
          val = proceed_key(key, map1, map2)
          Map.put(map, String.to_atom(key), val)
      end)
  end

  defp proceed_key(key, map1, map2) do
    {val1, val2} = {get(map1, key), get(map2, key)}
    cond do
      is_map(val1) -> deep_merge(val1, val2 || %{})
      has_key?(map2, key) -> val2
      true -> val1
    end
  end

  defp has_key?(map, key) when is_atom(key) do
    Map.has_key?(map, key) || Map.has_key?(map, Atom.to_string(key))
  end
  defp has_key?(map, key) do
    Map.has_key?(map, key) || Map.has_key?(map, String.to_atom(key))
  end
end
