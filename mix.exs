defmodule GeoSQL.Mixfile do
  use Mix.Project

  @source_url "https://github.com/expothecary/geo_sql"
  @version "1.4.1"

  def project do
    [
      app: :geo_sql,
      version: @version,
      elixir: "~> 1.15",
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
      {:geometry, "~> 1.1"},
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 3.13.0"},
      {:ecto_sql, "~> 3.0"},
      {:exqlite, "~> 0.32"},
      {:ecto_sqlite3, "~> 0.21"},
      {:jason, "~> 1.0"},

      # dev
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:igniter, "~> 0.6", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},

      # testing
      {:mix_test_watch, "~> 1.3", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      description:
        "Spatial databases and GIS SQL functions. Currently supports PostGIS, Spatialite, and Geopackage.",
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md"],
      maintainers: ["Aaron Seigo"],
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
        "Ecto Types": [~r/GeoSQL.Geometry.*/, GeoSQL.Int4],
        "SQL/MM": [~r/GeoSQL.MM.*/],
        "Non-Standard": [~r/GeoSQL.Common.*/],
        PostGIS: [~r/GeoSQL.PostGIS.*/],
        SpatiaLite: [~r/GeoSQL.SpatiaLite.*/],
        Utilities: [~r/GeoSQL.*Utils/]
      ]
    ]
  end

  # TODO: would be nice to find a way to get this from the test config.
  defp dynamic_test_repos(command),
    do: "#{command} --quiet -r GeoSQL.Test.PostGIS.Repo -r GeoSQL.Test.SpatiaLite.Repo"

  defp aliases do
    [
      test: [
        dynamic_test_repos("ecto.create"),
        dynamic_test_repos("ecto.migrate"),
        "test",
        dynamic_test_repos("ecto.drop")
      ]
    ]
  end
end
