defmodule Kongak.MixProject do
  use Mix.Project

  def project do
    [
      app: :kongak,
      version: "0.1.0",
      elixir: "~> 1.6",
      escript: escript(),
      deps: deps()
    ]
  end

  def escript do
    [main_module: Kongak.CLI]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:yaml_elixir, "~> 2.1"},
      {:httpoison, "~> 1.2"},
      {:jason, "~> 1.1"}
    ]
  end
end
