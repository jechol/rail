defmodule Rail.MixProject do
  use Mix.Project

  def project do
    [
      app: :rail,
      description: "Railway oriented programming for Elixir",
      docs: docs(),
      version: "0.2.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: "https://github.com/jechol/rail",
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
      links: %{"GitHub" => "https://github.com/jechol/rail"},
      maintainers: ["Jechol Lee (mr.jechol@gmail.com)"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "rail",
      canonical: "http://hexdocs.pm/rail",
      source_url: "https://github.com/jechol/rail",
      extras: [
        "README.md",
        "LICENSE"
      ]
    ]
  end
end
