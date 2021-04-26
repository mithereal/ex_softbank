# Softbank

**A Soft Bank To Handle your Financal Accounts**

***This Module has the following banking functions available***

Account Management ( a genserver that acts as the gateway between you and your accounts backed by a double entry accounting system )

Currency Conversion ( with auto update on conversion rates )

Custom Currencies ( added to the accounting system automatically)

Transfers(the producers send amount will be converted to match the recievers account currency type)


[![Build Status](https://travis-ci.org/mithereal/elixir-softbank.svg?branch=master)](https://travis-ci.org/mithereal/elixir-softbank)

[![Inline docs](http://inch-ci.org/github/mithereal/elixir-softbank.svg)](http://inch-ci.org/github/mithereal/elixir-softbank)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `soft_bank` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:soft_bank, "~> 0.2.0"}
  ]
end
```
## Creating the Database Tables

The Database Tables can be created by running the mix alias.

```elixir
mix install
```

## Usage

```elixir
# login to your account and return the balance
my_account_number = "demo-acct-number"
to_account_number = "demo-acct-number"
SoftBank.login(my_account_number)

amount = 20
SoftBank.deposit(amount,my_account_number)
SoftBank.withdrawl(amount,my_account_number)
SoftBank.transfer(amount,my_account_number,to_account_number)
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/softbank](https://hexdocs.pm/soft_bank).

