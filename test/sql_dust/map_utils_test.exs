defmodule SqlDust.MapUtilsTest do
  use ExUnit.Case
  alias SqlDust.MapUtils

  test "returns atom keys regardless of merge keys" do
    map1 = %{"a" => 4, "b" => 5, "c" => "this is c", d: nil}
    map2 = %{"a" => 4, b: 5, c: "this is c", d: nil}
    map3 = MapUtils.deep_merge(map1, map2)

    assert map3 == %{a: 4, b: 5, c: "this is c", d: nil}
  end

  test "it can handle string keys in the original map" do
    map1 = %{"a" => 4, "b" => 5}
    map2 = %{a: 1, b: 2}
    map3 = MapUtils.deep_merge(map1, map2)

    assert map3 == %{a: 1, b: 2}
  end

  test "it can handle string keys in the map that is merged" do
    map1 = %{a: 1, b: 2}
    map2 = %{"a" => 4, "b" => 5}
    map3 = MapUtils.deep_merge(map1, map2)

    assert map3 == %{a: 4, b: 5}
  end

  test "it merges values" do
    map1 = %{a: 1, b: 2}
    map2 = %{a: 4, b: 5}
    map3 = MapUtils.deep_merge(map1, map2)

    assert map3 == %{a: 4, b: 5}
  end

  test "it only overrides keys that exist in the second map" do
    map1 = %{a: 1, b: 2, c: 3}
    map2 = %{a: 4, b: 5}
    map3 = MapUtils.deep_merge(map1, map2)

    assert map3 == %{a: 4, b: 5, c: 3}
  end

  test "it adds the new keys from the second map" do
    map1 = %{a: 1, b: 2, c: 3}
    map2 = %{a: 4, b: 5, d: 6}
    map3 = MapUtils.deep_merge(map1, map2)

    assert map3 == %{a: 4, b: 5, c: 3, d: 6}
  end

  test "it merges nil values" do
    map1 = %{a: 1, b: 2}
    map2 = %{a: nil}
    map3 = MapUtils.deep_merge(map1, map2)

    assert map3 == %{a: nil, b: 2}
  end

  test "it merges false values" do
    map1 = %{a: 1, b: 2}
    map2 = %{a: false}
    map3 = MapUtils.deep_merge(map1, map2)

    assert map3 == %{a: false, b: 2}
  end

  test "it merges nested maps" do
    map1 = %{a: "3", b: %{c: 9}, d: 3}
    map2 = %{a: "3", b: %{c: 10}, d: 4}
    map3 = MapUtils.deep_merge(map1, map2)

    assert map3 == %{a: "3", b: %{c: 10}, d: 4}
  end

  test "it merges nil values in nested maps" do
    map1 = %{a: "3", b: %{c: 3}}
    map2 = %{a: nil, b: %{c: nil}}
    map3 = MapUtils.deep_merge(map1, map2)

    assert map3 == %{a: nil, b: %{c: nil}}
  end

  test "it merges false values in nested maps" do
    map1 = %{a: "3", b: %{c: 3}}
    map2 = %{a: false, b: %{c: false}}
    map3 = MapUtils.deep_merge(map1, map2)

    assert map3 == %{a: false, b: %{c: false}}
  end

  test "it merges string keys in nested maps" do
    map1 = %{a: "3", b: %{"c" => %{d: %{ "e" => 9001 }}}}
    map2 = %{a: "3", b: %{c: %{"d" => %{ "e" => 9001 }}}}
    map3 = MapUtils.deep_merge(map1, map2)

    assert map3 == %{a: "3", b: %{c: %{d: %{ e: 9001 }}}}
  end
end
