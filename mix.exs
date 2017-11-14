defmodule OrdMap.MixProject do
  use Mix.Project

  def project do
    [
      app: :ord_map,
      version: "0.1.0",
      elixir: "~> 1.6-dev",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      # build: mix compile && ex_doc "OrdMap" "0.1.0" "_build/dev/lib/ord_map/ebin"
      name: "OrdMap",
      source_url: "https://github.com/MartinKavik/ord_map",
      docs: [
        # The main page in the docs
        main: "OrdMap"
      ],

      # Package
      # build: mix compile && mix hex.audit && mix hex.build
      description: "Ordered map for Elixir lang",
      package: [
        maintainers: ["Martin Kavik"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/MartinKavik/ord_map"}
      ]
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
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end
end
