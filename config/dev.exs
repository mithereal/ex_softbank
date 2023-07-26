import Config
# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

config :soft_bank, :ecto_repos, [SoftBank.Repo]

config :soft_bank, SoftBank.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "soft_bank",
  hostname: "localhost",
  port: 55436,
  pool_size: 10

### Example using coinmarketcap for cryptocurrency rates
#  config :ex_money,
#  exchange_rates_retrieve_every: 300_000,
#  api_module: SoftBank.ExchangeRates.CoinMarketCap,
#  callback_module: SoftBank.ExchangeRates.CoinMarketCap.Callback,
#  exchange_rates_cache_module: Money.ExchangeRates.Cache.Ets,
#  exchange_rates_api_key: "your_api_key",
#  preload_historic_rates: nil,
#  retriever_options: nil,
#  log_failure: :warn,
#  log_info: :info,
#  log_success: nil,
#  json_library: Jason,
#  default_cldr_backend: SoftBank.Cldr
