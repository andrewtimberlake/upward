defmodule Upward do
  alias Upward.Appup

  # TODO: Add checks to see if the release is already installed, unpacked, permanent, etc
  # TODO: Check that there is a relup and appup for the transition (i.e. you con’t move from 1.0.0 to 1.0.2, but need to move through 1.0.1)
  def install(new_version) do
    app_name = Upward.Releases.app_name()
    current_version = Upward.Releases.current_version()

    with {:ok, new_version} <- Upward.Releases.set_unpacked(new_version),
         :ok <- Upward.Releases.install_release(new_version),
         # This is the env after the release is installed (Erlang called config_change) (Runtime configuration is not yet applied)
         release_env <- Application.get_all_env(app_name),
         # Ensure runtime configuration is loaded
         :ok <- Config.Provider.boot(),
         :ok <- Upward.Releases.make_permanent(new_version) do
      # This is the env after runtime configuration is applied
      {changed, new, removed} = Upward.Config.diff(app_name, release_env)
      {module, _} = Application.spec(app_name, :mod)
      module.config_change(changed, new, removed)

      up_down =
        if(Version.compare(current_version, new_version) == :gt,
          do: "Downgraded",
          else: "Upgraded"
        )

      IO.puts(IO.ANSI.green() <> "#{up_down} to #{new_version}" <> IO.ANSI.reset())
    else
      {:error, error} ->
        IO.puts(
          IO.ANSI.red() <>
            "* Error installing #{new_version}: #{inspect(error)}" <> IO.ANSI.reset()
        )
    end
  end

  def upgrade(new_version) do
    current_version = Upward.Releases.current_version()

    if Version.compare(current_version, new_version) == :lt do
      install(new_version)
    else
      IO.puts(
        IO.ANSI.red() <>
          "Cannot upgrade to #{new_version} from #{current_version}" <> IO.ANSI.reset()
      )
    end
  end

  def downgrade(new_version) do
    current_version = Upward.Releases.current_version()

    if Version.compare(current_version, new_version) == :gt do
      install(new_version)
    else
      IO.puts(
        IO.ANSI.red() <>
          "Cannot downgrade to #{new_version} from #{current_version}" <> IO.ANSI.reset()
      )
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

  def auto_appup(%Mix.Release{name: app_name, version: version, path: path} = release, opts \\ []) do
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

              _relup_path = Upward.Relup.make(release, previous_version)

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
        :ok = Upward.Releases.make_releases_file(app_name, version, path)

        IO.puts(
          IO.ANSI.yellow() <>
            "* not a patch release, skipping appup" <> IO.ANSI.reset()
        )
      end
    else
      :ok = Upward.Releases.make_releases_file(app_name, version, path)

      IO.puts(
        IO.ANSI.yellow() <>
          "* no previous release found, skipping appup" <> IO.ANSI.reset()
      )
    end

    release
  end
end
