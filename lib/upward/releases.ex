Code.ensure_loaded?(:release_handler)

defmodule Upward.Releases do
  @behaviour Config.Provider

  @impl Config.Provider
  def init(opts), do: opts

  @impl Config.Provider
  def load(config, {app_name, version}) do
    version = Version.parse!(version)

    case version do
      %Version{patch: 0} ->
        IO.puts(
          IO.ANSI.green() <> "Making RELEASES file for #{app_name} #{version}" <> IO.ANSI.reset()
        )

        make_releases(app_name, version)

      _ ->
        nil
    end

    config
  end

  def app_name do
    {:ok, _} = Application.ensure_all_started(:sasl)
    [{name, _vsn, _, _}] = :release_handler.which_releases(:permanent)
    to_string(name)
  end

  def make_releases(app_name, version) do
    version = Upward.Utils.parse_version(version)

    {:ok, _} = Application.ensure_all_started(:sasl)

    path = File.cwd!()
    releases_path = Path.join(path, "releases")

    :ok =
      :release_handler.create_RELEASES(
        String.to_charlist(path),
        String.to_charlist(releases_path),
        String.to_charlist(Path.join(releases_path, "#{version}/#{app_name}.rel")),
        []
      )
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
