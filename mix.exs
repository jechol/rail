defmodule Reather.MixProject do
  use Mix.Project

  def project do
    [
      app: :reather_lite,
      description: "A lighter version of Reather; Combination of Reader and Either monads",
      docs: docs(),
      version: "0.2.6",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: "https://github.com/SeokminHong/reather-lite",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.lcov": :test,
        "coveralls.github": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/SeokminHong/reather-lite"},
      maintainers: ["Seokmin Hong (ghdtjrald240@gmail.com)"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 0.4", only: [:dev, :test]},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "reather-lite",
      canonical: "http://hexdocs.pm/reather_lite",
      source_url: "https://github.com/SeokminHong/reather-lite",
      extras: [
        "README.md",
        "LICENSE"
      ]
    ]
  end
end
