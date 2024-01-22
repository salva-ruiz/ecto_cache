defmodule EctoCache.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/salva-ruiz/ecto_cache"

  def project do
    [
      app: :ecto_cache,
      version: "1.0.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @source_url,

      # Hex
      description: "A library to cache Ecto query results.",
      package: package(),

      # Docs
      name: "EctoCache",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp package() do
    [
      maintainers: ["Salva Ruiz"],
      files: ~w(lib .formatter.exs mix.exs README.md CHANGELOG.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "EctoCache",
      source_ref: "v#{@version}",
      extra_section: "GUIDES",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      extras: ["CHANGELOG.md", "README.md"]
    ]
  end
end
