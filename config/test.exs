import Config
# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

config :soft_bank, SoftBank.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "soft_bank",
  hostname: "localhost",
  port: 55436,
  pool_size: 10

config :soft_bank, SoftBank.TestRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "soft_bank",
  hostname: "localhost",
  port: 55436,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
