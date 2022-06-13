defmodule SoftBank.MixProject do
  use Mix.Project

  @version "1.1.0"
  @source_url "https://github.com/mithereal/ex_softbank.git"

  def project do
    [
      app: :soft_bank,
      version: @version,
      elixir: "~> 1.9",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      aliases: aliases(),
      docs: docs(),
      name: "soft_bank",
      source_url: @source_url,
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SoftBank.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 3.5"},
      {:ecto_sql, "~> 3.5"},
      {:jason, "~> 1.0"},
      {:ex_money, ">= 0.0.0"},
      {:ex_money_sql, "~> 1.0"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:nanoid, "~> 2.0.1"},
      {:inch_ex, ">= 0.0.0", only: :docs},
      {:faker, "~> 0.17", only: :test},
      {:ex_machina, ">= 0.0.0", only: :test}
    ]
  end

  defp description() do
    "A Soft Bank To Handle your Financial Accounts."
  end

  defp package() do
    [
      name: "soft_bank",
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Jason Clark"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mithereal/ex_softbank"}
    ]
  end

  defp aliases do
    [
      c: "compile",
      test: ["ecto.drop --quiet", "ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      install: ["SoftBank.install", "ecto.setup"]
    ]
  end

  defp docs do
    [
      main: "readme",
      homepage_url: @source_url,
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end

  # This makes sure your factory and any other modules in test/support are compiled
  # when in the test environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
