defmodule Upward do
  alias Upward.Appup

  def auto_appup(%Mix.Release{name: app_name, version: version, path: path} = release) do
    previous_version_path =
      Path.wildcard(Path.join(path, "releases/*"))
      |> Enum.filter(&File.dir?/1)
      |> Enum.reject(&(Path.basename(&1) == version))
      |> Enum.filter(&(Version.compare(Path.basename(&1), version) == :lt))
      |> Enum.sort_by(&Path.basename(&1), :desc)
      |> List.first()

    previous_version = Path.basename(previous_version_path)

    {:ok, appup} =
      Appup.make(
        app_name,
        previous_version,
        version,
        Path.join(path, "lib/#{app_name}-#{previous_version}"),
        Path.join(path, "lib/#{app_name}-#{version}")
      )

    File.write(
      Path.join([path, "lib/#{app_name}-#{version}/ebin/#{app_name}.appup"]),
      :io_lib.format(~c"~tp.~n", [appup])
    )

    release
  end
end
