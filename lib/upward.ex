defmodule Upward do
  alias Upward.Appup

  def auto_appup(%Mix.Release{name: app_name, version: version, path: path} = release) do
    # Get the latest previous release
    previous_release_path =
      Path.wildcard(Path.join(path, "releases/*"))
      |> Enum.filter(&File.dir?/1)
      |> Enum.reject(&(Path.basename(&1) == version))
      |> Enum.filter(&(Version.compare(Path.basename(&1), version) == :lt))
      |> Enum.sort_by(&Path.basename(&1), :desc)
      |> List.first()

    if previous_release_path do
      previous_version = Path.basename(previous_release_path)

      if is_patch_release?(version, previous_version) do
        previous_version_path = Path.join(path, "lib/#{app_name}-#{previous_version}")

        if File.dir?(previous_version_path) do
          current_version_path = Path.join(path, "lib/#{app_name}-#{version}")

          case Appup.make(
                 app_name,
                 previous_version,
                 version,
                 previous_version_path,
                 current_version_path
               ) do
            {:ok, appup} ->
              IO.puts("Writing appup file")

              File.write(
                Path.join([path, "lib/#{app_name}-#{version}/ebin/#{app_name}.appup"]),
                :io_lib.format(~c"~tp.~n", [appup])
              )

            error ->
              IO.puts("Unable to generate appup: #{inspect(error)}")
          end
        else
          IO.puts("Previous version path does not exist, skipping appup")
        end
      else
        IO.puts("Not a patch release, skipping appup")
      end
    end

    release
  end

  defp is_patch_release?(
         %Version{major: major, minor: minor},
         %Version{major: major, minor: minor}
       ) do
    true
  end

  defp is_patch_release?(%Version{}, %Version{}) do
    false
  end

  defp is_patch_release?(v1, v2) when is_binary(v1) do
    is_patch_release?(Version.parse!(v1), v2)
  end

  defp is_patch_release?(v1, v2) when is_binary(v2) do
    is_patch_release?(v1, Version.parse!(v2))
  end
end
