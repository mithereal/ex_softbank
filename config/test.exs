use Mix.Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

config :soft_bank, SoftBank.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "public",
  hostname: "localhost",
  pool_size: 10

config :soft_bank, app_mode: "test"

config :soft_bank,
  default_currency: :USD,
  separator: ".",
  delimiter: ",",
  symbol: false,
  symbol_on_right: false,
  symbol_space: false,
  fractional_unit: false

config :soft_bank,
  pool_size: 10,
  pool_max_overflow: 1

config :soft_bank,
  # source: CurrencyConversion.Source.Fixer,
  source: SoftBank.Currency.Conversion.Source.Test,
  # source_api_key: "FIXER_ACCESS_KEY",
  # defaults to http since free access key only supports http

  source_protocol: "https",
  refresh_interval: 86_400_000
