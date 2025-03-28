defmodule Dragonite.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :dragonite,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      description: """
      Dragonite - Fast, reliable and configurable EDI parser (encode & decode), seeker & rule runner.
      """,
      package: package(),
      deps: deps(),
      name: "Dragonite",
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: []
    ]
  end

  def application do
    [
      mod: {Dragonite.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      name: "dragonite",
      maintainers: ["Jorge Garrido"],
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/zgbjgg/dragonite"}
    ]
  end

  defp docs do
    [
      main: "Dragonite",
      source_ref: "v#{@version}",
      source_url: "https://github.com/zgbjgg/dragonite"
    ]
  end

  defp deps do
    [
      {:yaml_elixir, "~> 2.7"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false, optional: true},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
