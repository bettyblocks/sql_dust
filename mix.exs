defmodule SqlDust.Mixfile do
  use Mix.Project

  def project do
    [app: :sql_dust,
     version: "0.4.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:inflex, "~> 2.0"},
      {:ecto, "~> 3.7", optional: true},
      {:exprof, "~> 0.2", only: :dev},
      {:benchfella, "~> 0.3", only: :dev},
      {:ex_doc, "~> 0.25", only: :dev},
      {:credo, "~> 1.5", only: [:dev, :test]},
    ]
  end

  defp description do
    """
    Easy. Simple. Powerful. Generate (complex) SQL queries using magical Elixir SQL dust.
    """
  end

  defp package do
    [
      maintainers: ["Paul Engel", "Daniel Willemse", "Peter Arentsen"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/bettyblocks/sql_dust"}
    ]
  end
end
