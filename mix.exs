defmodule Upward.MixProject do
  use Mix.Project

  @github_url "https://github.com/andrewtimberlake/upward"
  @version "0.0.1"

  def project do
    [
      app: :upward,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @github_url,
      docs: fn ->
        [
          source_ref: "#{@version}",
          canonical: "http://hexdocs.pm/upward",
          main: "Upward",
          source_url: @github_url,
          extras: ["README.md"]
        ]
      end,
      description: description(),
      package: package()
    ]
  end

  defp description do
    """
    A library to assist with hot-code upgrades with Elixir releases
    """
  end

  defp package do
    [
      maintainers: ["Andrew Timberlake"],
      contributors: ["Andrew Timberlake"],
      licenses: ["MIT"],
      links: %{"Github" => @github_url}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:castle, "~> 0.0"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
