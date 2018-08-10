# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :soft_bank, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:soft_bank, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env()}.exs"

config :soft_bank,
       soft_bank: [SoftBank.Repo]
       
       
config :soft_bank, SoftBank.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "",
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
       #source: SoftBank.Currency.Conversion.Source.Fixer,
       source: SoftBank.Currency.Conversion.Source.Test,
       #source_api_key: "FIXER_ACCESS_KEY",
       # defaults to http since free access key only supports http

       source_protocol: "https",
       refresh_interval: 86_400_000

import_config "#{Mix.env()}.exs"
