defmodule GeoSQL.Mixfile do
  use Mix.Project

  @source_url "https://github.com/aseigo/geo_sql"
  @version "0.1.0"

  def project do
    [
      app: :geo_sql,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      name: "GeoSQL",
      deps: deps(),
      package: package(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:geo, "~> 4.0"},
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:jason, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.3", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      description: "GIS functions for Ecto.",
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md"],
      maintainers: ["Aaron Seigoh"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      extras: ["CHANGELOG.md", "README.md"],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"],
      groups_for_modules: [
        "SQL MM Standard": [~r/GeoSQL.MM[23].*/],
        "Common Non-Standard": [~r/GeoSQL.Common.*/],
        "PostGIS-Specific": [~r/GeoSQL.PostGIS.*/]
      ]
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test", "ecto.drop --quiet"]
    ]
  end
end
