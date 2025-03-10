defmodule Upward.Relup do
  def make(%Mix.Release{name: app_name, version: version, path: path}, previous_version) do
    IO.puts(IO.ANSI.green() <> "* Generating relup file" <> IO.ANSI.reset())

    current_relup_path = Path.join(path, "releases/#{version}/#{app_name}")

    previous_relup_path = Path.join(path, "releases/#{previous_version}/#{app_name}")

    :systools.make_relup(
      String.to_charlist(current_relup_path),
      [String.to_charlist(previous_relup_path)],
      [String.to_charlist(previous_relup_path)],
      [
        {:outdir, String.to_charlist(Path.join(path, "releases/#{version}"))},
        {:path,
         Enum.map(
           [
             Path.join(path, "lib/#{app_name}-#{previous_version}/ebin"),
             Path.join(path, "lib/#{app_name}-#{version}/ebin")
           ],
           &String.to_charlist/1
         )}
      ]
    )
  end
end
