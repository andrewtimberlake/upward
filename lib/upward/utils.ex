defmodule Upward.Utils do
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

  def is_base_patch?(%Version{patch: 0}), do: true
  def is_base_patch?(%Version{}), do: false

  def is_base_patch?(version) when is_binary(version) do
    version
    |> Version.parse!()
    |> is_base_patch?()
  end

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
