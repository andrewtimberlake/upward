defmodule Upward.Utils do
  @moduledoc """
  General utility functions.
  """

  @doc """
  Finds the previous release path within the build directory.
  """
  def previous_release_path(paths, current_version) do
    paths
    |> Enum.map(fn path ->
      {parse_version(Path.basename(path)), path}
    end)
    |> Enum.reject(&(elem(&1, 0) == :error))
    |> Enum.filter(&(Version.compare(elem(&1, 0), current_version) == :lt))
    |> Enum.sort_by(&elem(&1, 0), :desc)
    |> Enum.map(&elem(&1, 1))
    |> List.first()
  end

  @doc """
  Checks if the difference between two versions is a patch release.

  Examples:
      Upward.Utils.patch_release?("1.0.0", "1.0.1")
      iex> true

      Upward.Utils.patch_release?("1.0.0", "1.1.0")
      iex> false

  """
  def patch_release?(
        %Version{major: major, minor: minor},
        %Version{major: major, minor: minor}
      ) do
    true
  end

  def patch_release?(%Version{}, %Version{}) do
    false
  end

  def patch_release?(v1, v2) when is_binary(v1) do
    patch_release?(parse_version(v1), v2)
  end

  def patch_release?(v1, v2) when is_binary(v2) do
    patch_release?(v1, parse_version(v2))
  end

  @doc """
  Checks if a version is a base patch version.

  Base patch versions are versions that have a patch number of 0.

  Examples:
      Upward.Utils.is_base_patch?("1.0.0")
      iex> true

      Upward.Utils.is_base_patch?("1.0.1")
      iex> false
  """
  def is_base_patch?(%Version{patch: 0}), do: true
  def is_base_patch?(%Version{}), do: false

  def is_base_patch?(version) when is_binary(version) do
    version
    |> Version.parse!()
    |> is_base_patch?()
  end

  @doc """
  Parses a version string into a Version struct.

  Examples:
      Upward.Utils.parse_version("1.0.0")
      iex> %Version{major: 1, minor: 0, patch: 0}
  """
  def parse_version(%Version{} = version), do: version

  def parse_version(version) when is_binary(version) do
    case Version.parse(version) do
      {:ok, version} -> version
      :error -> :error
    end
  end

  def parse_version(version) when is_list(version) do
    parse_version(List.to_string(version))
  end
end
