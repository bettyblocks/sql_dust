defmodule TalkTest do
  use SqlDust.ExUnit.Case
  require Logger

  setup do
    Logger.configure(level: :debug)
    on_exit fn() -> Logger.configure(level: :info) end
    :ok
  end

  test "example1" do
    title = "HI"
    assert TalkTest.SqlDust.example1(title) == TalkTest.Ecto.example1(title) |> IO.inspect()
  end

  test "example2" do
    assert TalkTest.SqlDust.example2(2) == TalkTest.Ecto.example2(2) |> IO.inspect()
  end

  test "example3" do
    assert TalkTest.SqlDust.example3(10) == TalkTest.Ecto.example3(10) |> IO.inspect()
  end

  test "example4" do
    assert TalkTest.SqlDust.example4("e") == TalkTest.Ecto.example4("e") |> IO.inspect()
  end
end
