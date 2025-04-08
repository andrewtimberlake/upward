Code.ensure_loaded?(:release_handler)

defmodule Upward.Releases do
  def app_name do
    {:ok, _} = Application.ensure_all_started(:sasl)
    [{name, _vsn, _, _}] = :release_handler.which_releases(:permanent)
    String.to_existing_atom(to_string(name))
  end

  def current_version do
    [{_name, vsn, _, _}] = :release_handler.which_releases(:permanent)
    Upward.Utils.parse_version(vsn)
  end

  def make_releases_file(app_name, version, path \\ File.cwd!())

  def make_releases_file(app_name, %Version{patch: 0} = version, path) do
    version = Upward.Utils.parse_version(version)

    {:ok, _} = Application.ensure_all_started(:sasl)

    releases_path = Path.join(path, "releases")

    :ok =
      :release_handler.create_RELEASES(
        # If we don’t provide a root path, then the release file contains relative paths to the libs which is what we
        # need for a RELEASES file generated during release (on build machine) rather then during install (on target machine)
        "",
        String.to_charlist(releases_path),
        String.to_charlist(Path.join(releases_path, "#{version}/#{app_name}.rel")),
        []
      )
  end

  def make_releases_file(_app_name, %Version{}, _path) do
    :ok
  end

  def make_releases_file(app_name, version, path) do
    version = Upward.Utils.parse_version(version)
    make_releases_file(app_name, version, path)
  end

  def set_unpacked(version) do
    app_name = app_name()
    path = File.cwd!()
    releases_path = Path.join(path, "releases")
    release_path = Path.join(releases_path, "#{version}/#{app_name}.rel")

    if File.exists?(release_path) do
      result =
        :release_handler.set_unpacked(
          String.to_charlist(release_path),
          []
        )

      case result do
        {:ok, vsn} ->
          {:ok, Upward.Utils.parse_version(vsn)}

        {:error, {:existing_release, vsn}} ->
          {:ok, Upward.Utils.parse_version(vsn)}

        error ->
          error
      end
    else
      {:error, "Release file does not exist: #{release_path}"}
    end
  end

  def install_release(version) do
    case :release_handler.install_release(~c"#{version}") do
      {:ok, _vsn, _} ->
        # IO.puts(IO.ANSI.green() <> "Installed release #{vsn}" <> IO.ANSI.reset())
        :ok

      {:error, {:already_installed, _vsn}} ->
        # IO.puts(IO.ANSI.green() <> "Installed release #{vsn}" <> IO.ANSI.reset())
        :ok

      error ->
        # IO.puts(
        #   IO.ANSI.red() <>
        #     "Error installing release #{version}: #{inspect(error)}" <> IO.ANSI.reset()
        # )
        error
    end
  end

  def make_permanent(version) do
    case :release_handler.make_permanent(~c"#{version}") do
      :ok ->
        # IO.puts(IO.ANSI.green() <> "Made release #{version} permanent" <> IO.ANSI.reset())
        :ok

      error ->
        # IO.puts(
        #   IO.ANSI.red() <>
        #     "Error making release #{version} permanent: #{inspect(error)}" <> IO.ANSI.reset()
        # )
        error
    end
  end

  def releases do
    :release_handler.which_releases()
    |> Enum.map(fn {_, vsn, _, status} ->
      {to_string(vsn), status}
    end)
  end
end
