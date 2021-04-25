# Softbank

**A Soft Bank To Handle your Financal Accounts**

***This Module has the following banking functions available***

Tellers( a pool of tellers so multiple processes can access. )

Currency Conversion (with auto update on conversion rates)

Transfers(send amount will be converted to match the recievers account currency type)



[![Build Status](https://travis-ci.org/mithereal/elixir-softbank.svg?branch=master)](https://travis-ci.org/mithereal/elixir-softbank)

[![Inline docs](http://inch-ci.org/github/mithereal/elixir-softbank.svg)](http://inch-ci.org/github/mithereal/elixir-softbank)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `soft_bank` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:soft_bank, "~> 0.1.4"}
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
account_number = "demo-acct-number"
SoftBank.login(account_number)

#amount = 20.00
#Bank.deposit(amount)
#Bank.withdrawl(amount)
#Bank.transfer(amount)
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/softbank](https://hexdocs.pm/soft_bank).

