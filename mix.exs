defmodule SoftBank.MixProject do
  use Mix.Project

  def project do
    [
      app: :soft_bank,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      build_embedded: Mix.env == :prod,
      description: description(),
      package: package(),
      name: "soft bank",
      source_url: "https://github.com/mithereal/elixir-softbank"
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
      {:httpotion, "~> 3.1.0"},
      {:poison, "~> 3.0"},
       {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
  
   
  defp description() do
    "A Soft Bank To Handle your Financal Accounts."
  end

  defp package() do
    [
      name: "Soft Bank",
      files: ["lib",  "mix.exs", "README*"],
      maintainers: ["Jason Clark"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mithereal/elixir-softbank"}
    ]
  end
end
