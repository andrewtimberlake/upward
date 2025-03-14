defmodule Upward.UtilsTest do
  use ExUnit.Case
  doctest Upward.Utils

  test "previous_release_path/2" do
    current_version = "0.10.1"

    paths = [
      "releases/0.10.0",
      "releases/0.10.1",
      "releases/0.9.13",
      "releases/0.9.14",
      "releases/0.9.15"
    ]

    assert "releases/0.10.0" = Upward.Utils.previous_release_path(paths, current_version)
  end

  test "previous_release_path/2 with invalid directory and file" do
    current_version = "0.10.1"

    paths = [
      "data.txt",
      "releases/0.10.0",
      "releases/0.10.1",
      "releases/0.9.13",
      "releases/0.9.14",
      "releases/0.9.15",
      "wat"
    ]

    assert "releases/0.10.0" = Upward.Utils.previous_release_path(paths, current_version)
  end

  test "patch_release?/2" do
    assert Upward.Utils.patch_release?("0.10.0", "0.10.1")
    refute Upward.Utils.patch_release?("0.10.0", "0.11.0")

    assert Upward.Utils.patch_release?(%Version{major: 0, minor: 10, patch: 0}, %Version{
             major: 0,
             minor: 10,
             patch: 1
           })

    refute Upward.Utils.patch_release?(%Version{major: 0, minor: 10, patch: 0}, %Version{
             major: 0,
             minor: 11,
             patch: 0
           })
  end

  test "parse_version/1" do
    assert %Version{major: 0, minor: 10, patch: 0} = Upward.Utils.parse_version("0.10.0")
    assert %Version{major: 0, minor: 10, patch: 0} = Upward.Utils.parse_version(~c"0.10.0")

    assert %Version{major: 0, minor: 10, patch: 0} =
             Upward.Utils.parse_version(%Version{major: 0, minor: 10, patch: 0})
  end
end
