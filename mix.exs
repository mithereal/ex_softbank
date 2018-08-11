defmodule SoftBank.MixProject do
  use Mix.Project
  @version "0.0.1"
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
      name: "soft bank",
      source_url: "https://github.com/mithereal/elixir-softbank",
      docs: [source_ref: "v#{@version}", main: "Bank",
        canonical: "",
        source_url: "https://github.com/mithereal/softbank"]
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
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:poolboy, "~> 1.5"}
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
