defmodule SoftBank.MixProject do
  use Mix.Project
  
  @version "0.1.2"
  @source_url "https://github.com/mithereal/elixir-softbank"

  def project do
    [
      app: :soft_bank,
      version: @version ,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      build_embedded: Mix.env == :prod,
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
      extra_applications: [:logger, :httpotion],
      mod: {SoftBank.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:ecto, "~> 2.1"},
      {:postgrex, ">= 0.0.0"},
      {:httpotion, "~> 3.1"},
      {:poison, "~> 3.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:poolboy, "~> 1.5"},
      {:nanoid, "~> 2.0.1"},
      {:inch_ex, ">= 0.0.0", only: :docs}
    ]
  end
  
   
  defp description() do
    "A Soft Bank To Handle your Financal Accounts."
  end

  defp package() do
    [
      name: "soft_bank",
      files: ["lib",  "mix.exs", "README.md"],
      maintainers: ["Jason Clark"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mithereal/elixir-softbank"}
    ]
  end

  defp aliases do
    [
      c: "compile", 
      test: ["test"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/migrations/tables.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "install": ["ecto.setup"]
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

end
