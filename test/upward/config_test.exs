defmodule Upward.ConfigTest do
  use ExUnit.Case

  test "diff/2" do
    previous_env = [a: 1, b: 2, c: 3, d: 4]
    current_env = [a: 1, b: 2, c: 4, e: 5]

    assert Upward.Config.diff(current_env, previous_env) == {[c: 4], [e: 5], [:d]}
  end
end
