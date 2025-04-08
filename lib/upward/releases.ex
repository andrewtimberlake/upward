Code.ensure_loaded?(:release_handler)

defmodule Upward.Releases do
  @moduledoc """
  A utility module for managing releases.
  """

  @doc """
  Get the name of the running application.
  """
  @spec app_name() :: atom
  def app_name do
    {:ok, _} = Application.ensure_all_started(:sasl)
    [{name, _vsn, _, _}] = :release_handler.which_releases(:permanent)
    String.to_existing_atom(to_string(name))
  end

  @doc """
  Get the current version of the running application.
  """
  @spec current_version() :: Version.t()
  def current_version do
    [{_name, vsn, _, _}] = :release_handler.which_releases(:permanent)
    Upward.Utils.parse_version(vsn)
  end

  @doc """
  Get the next patch version (of the running application).
  """
  @spec next_version(Version.t()) :: Version.t()
  def next_version(%Version{patch: patch} = current_version \\ current_version()) do
    %{current_version | patch: patch + 1}
  end

  @doc """
  Get the previous installed patch version of the running application.
  """
  @spec previous_version() :: {:ok, Version.t()} | {:error, String.t()}
  def previous_version() do
    case current_version() do
      %Version{patch: 0} ->
        {:error, "Cannot downgrade past the first patch version"}

      current_version ->
        releases()
        |> Enum.map(&elem(&1, 0))
        |> Enum.find(fn vsn ->
          Version.compare(vsn, current_version) == :lt
        end) || {:error, "No previous version found"}
    end
  end

  @doc """
  Make a RELEASES file for a given version.

  This is only done for versions x.y.0 and creates a RELEASES file to be included with a release.
  """
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

  @doc """
  Remove the RELEASES file (from the build directory) so it is not included with a patch release.
  """
  def remove_releases_file(path \\ File.cwd!()) do
    releases_path = Path.join(path, "releases/RELEASES")

    if File.exists?(releases_path) do
      IO.puts("Removing #{releases_path}")
      File.rm_rf!(releases_path)
    end
  end

  @doc """
  This is as part of a version install and assumes that the release tarball has been extracted into the release directory.
  """
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

  @doc """
  Install a release.

  This will ignore an already installed release.
  """
  def install_release(version) do
    case :release_handler.install_release(~c"#{version}") do
      {:ok, _vsn, _} ->
        :ok

      {:error, {:already_installed, _vsn}} ->
        # Ignore an already installed release
        :ok

      error ->
        error
    end
  end

  @doc """
  Make a release permanent.
  """
  def make_permanent(version) do
    case :release_handler.make_permanent(~c"#{version}") do
      :ok ->
        :ok

      error ->
        error
    end
  end

  @doc """
  Get a list of all the releases along with their status.
  """
  @spec releases() :: [{Version.t(), status :: :unpacked | :current | :permanent | :old}]
  def releases do
    :release_handler.which_releases()
    |> Enum.map(fn {_, vsn, _, status} ->
      {Upward.Utils.parse_version(vsn), status}
    end)
  end
end
