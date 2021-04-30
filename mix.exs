defmodule SoftBank.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/mithereal/elixir-softbank"

  def project do
    [
      app: :soft_bank,
      version: @version,
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      build_embedded: Mix.env() == :prod,
      description: description(),
      package: package(),
      name: "soft_bank",
      aliases: aliases(),
      source_url: "https://github.com/mithereal/elixir-softbank",
      docs: docs()
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 3.5"},
      {:ecto_sql, "~> 3.5"},
      {:jason, "~> 1.0"},
      {:ex_money, "5.5.2"},
      {:ex_money_sql, "~> 1.0"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:nanoid, "~> 2.0.1"},
      {:inch_ex, ">= 0.0.0", only: :docs},
      {:faker, "~> 0.16"},
      {:ex_machina, "~> 2.7.0", only: :test}
    ]
  end

  defp description() do
    "A Soft Bank To Handle your Financal Accounts."
  end

  defp package() do
    [
      name: "soft_bank",
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Jason Clark"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mithereal/elixir-softbank"}
    ]
  end

  defp aliases do
    [
      c: "compile",
      test: ["test"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      install: ["ecto.setup"]
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
  defp elixirc_paths, do: ["lib"]
end
