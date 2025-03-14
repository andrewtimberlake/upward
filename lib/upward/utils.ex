defmodule Upward.Utils do
  def previous_release_path(paths, current_version) do
    paths
    |> Enum.reject(&(Path.basename(&1) == current_version))
    |> Enum.reject(&(Version.parse(Path.basename(&1)) == :error))
    |> Enum.filter(&(Version.compare(Path.basename(&1), current_version) == :lt))
    |> Enum.sort_by(&Path.basename(&1), :asc)
    |> List.first()
  end

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

  def parse_version(%Version{} = version), do: version
  def parse_version(version) when is_binary(version), do: Version.parse!(version)
  def parse_version(version) when is_list(version), do: Version.parse!(List.to_string(version))
end
