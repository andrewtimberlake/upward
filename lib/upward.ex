defmodule Upward do
  alias Upward.Appup

  # TODO: Add checks to see if the release is already installed, unpacked, permanent, etc
  # TODO: Maybe rename this to cover change in any version direction
  # TODO: Check that there is a relup and appup for the transition (i.e. you con’t move from 1.0.0 to 1.0.2, but need to move through 1.0.1)
  def upgrade(version) do
    with {:ok, version} <- Upward.Releases.set_unpacked(version),
         :ok <- Upward.Releases.install_release(version),
         :ok <- Upward.Releases.make_permanent(version) do
      IO.puts(IO.ANSI.green() <> "Upgraded to #{version}" <> IO.ANSI.reset())
    else
      {:error, error} ->
        IO.puts(IO.ANSI.red() <> "* Error setting unpacked: #{inspect(error)}" <> IO.ANSI.reset())
    end
  end

  def releases do
    releases = Upward.Releases.releases()

    max_width =
      releases
      |> Enum.map(&elem(&1, 0))
      |> Enum.map(&String.length/1)
      |> Enum.max()

    releases
    |> Enum.sort_by(fn {vsn, _status} -> vsn end)
    |> Enum.each(fn {vsn, status} ->
      IO.puts(
        IO.ANSI.cyan() <>
          " #{String.pad_leading(vsn, max_width)} #{status}" <> IO.ANSI.reset()
      )
    end)
  end

  def prepare(%Mix.Release{name: app_name, version: version} = release) do
    %{config_providers: config_providers} = release
    config_providers = [{Upward.Releases, {app_name, version}} | config_providers]
    %{release | config_providers: config_providers}
  end

  def auto_appup(%Mix.Release{name: app_name, version: version, path: path} = release, opts \\ []) do
    # TODO: Check if the config provider is added and warn about adding &Upward.prepare/1 to the release config

    # Get the latest previous release
    previous_release_path =
      Path.wildcard(Path.join(path, "releases/*"))
      |> Enum.filter(&File.dir?/1)
      |> Upward.Utils.previous_release_path(version)

    if previous_release_path do
      previous_version = Path.basename(previous_release_path)

      IO.puts(
        IO.ANSI.yellow() <> "* upgrade from #{previous_version} to #{version}" <> IO.ANSI.reset()
      )

      if Upward.Utils.patch_release?(version, previous_version) do
        previous_version_path = Path.join(path, "lib/#{app_name}-#{previous_version}")

        if File.dir?(previous_version_path) do
          current_version_path = Path.join(path, "lib/#{app_name}-#{version}")

          case Appup.make(
                 app_name,
                 previous_version,
                 version,
                 previous_version_path,
                 current_version_path,
                 Keyword.get(opts, :transforms, [])
               ) do
            {:ok, appup} ->
              IO.puts(IO.ANSI.green() <> "* writing appup file" <> IO.ANSI.reset())

              File.write(
                Path.join([path, "lib/#{app_name}-#{version}/ebin/#{app_name}.appup"]),
                :io_lib.format(~c"~tp.~n", [appup])
              )

              Upward.Relup.make(release, previous_version)

            error ->
              IO.puts(
                IO.ANSI.red() <>
                  "* unable to generate appup: #{inspect(error)}" <> IO.ANSI.reset()
              )
          end
        else
          IO.puts(
            IO.ANSI.yellow() <>
              "* previous version path does not exist, skipping appup" <> IO.ANSI.reset()
          )
        end
      else
        IO.puts(
          IO.ANSI.yellow() <>
            "* not a patch release, skipping appup" <> IO.ANSI.reset()
        )
      end
    else
      IO.puts(
        IO.ANSI.yellow() <>
          "* no previous release found, skipping appup" <> IO.ANSI.reset()
      )
    end

    release
  end
end
