defmodule UpwardTest do
  use ExUnit.Case
  doctest Upward

  test "greets the world" do
    assert Upward.hello() == :world
  end
end
