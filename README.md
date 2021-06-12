# Softbank

**A Soft Bank To Handle your Financal Accounts**

***This Module has the following banking functions available***

Account Management ( a genserver that acts as the gateway between you and your accounts backed by a double entry accounting system )

Currency Conversion ( with auto update on conversion rates )

Custom Currencies ( added to the accounting system automatically)

Transfers(the producers send amount will be converted to match the recievers account currency type)

Typically the Account Management genserver would be considered an anti pattern, however I needed a way to persist the state of my accounts ledgers in order to decouple accounting from user management. 

This allows an accounts ledger state to be persisted for a ttl, when some other system process needs also to use the account ledger data the ttl is reset and state persisted until timeout occurs. 


[![Inline docs](http://inch-ci.org/github/mithereal/elixir-softbank.svg)](http://inch-ci.org/github/mithereal/elixir-softbank)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `soft_bank` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:soft_bank, "~> 1.0.0"}
  ]
end
```
## Creating the Database Tables

The Database Tables can be created by running the mix alias.

```elixir
mix install
```

## Config

Add the following to your config.exs
```elixir
config :soft_bank, :ecto_repos, [SoftBank.Repo]

config :soft_bank,
  soft_bank: [SoftBank.Repo]

config :ex_money,
  exchange_rates_retrieve_every: 300_000,
  api_module: Money.ExchangeRates.OpenExchangeRates,
  callback_module: Money.ExchangeRates.Callback,
  exchange_rates_cache_module: Money.ExchangeRates.Cache.Ets,
  preload_historic_rates: nil,
  retriever_options: nil,
  log_failure: :warn,
  log_info: :info,
  log_success: nil,
  json_library: Jason,
  default_cldr_backend: SoftBank.Cldr

config :ex_cldr,
  json_library: Jason
```

Add the following to your dev and/or prod config
```elixir
config :soft_bank, :ecto_repos, [SoftBank.Repo]

config :soft_bank,
  soft_bank: [SoftBank.Repo]

config :soft_bank, SoftBank.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "softbank_dev",
  hostname: "localhost",
  pool_size: 10
```

## Usage

```elixir
# login to your account and return the balance
my_account_number = "from-acct-number"
to_account_number = "to-acct-number"
SoftBank.login(my_account_number)

amount = Money.new :USD, 10
SoftBank.deposit(amount,my_account_number)
SoftBank.withdrawl(amount,my_account_number)
SoftBank.transfer(amount,my_account_number,to_account_number)
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/soft_bank](https://hexdocs.pm/soft_bank).

