defmodule SoftBank.TestFactory do
  use ExMachina.Ecto, repo: SoftBank.TestRepo

  alias SoftBank.{Account, Amount, Entry}

  @chars "ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.split("")
  @default_currency "USD"

  def account_factory do
    %Account{
      name: "My Assets",
      type: "asset",
      contra: false,
      hash: generate_rand_string(),
      currency: @default_currency
    }
  end

  def entry_factory do
    %Entry{
      description: "Investing in Koenigsegg",
      date: DateTime.utc_now(),
      amounts: [build(:credit), build(:debit)]
    }
  end

  def credit_factory do
    %Amount{
      amount: Decimal.new(125_000.00),
      type: "credit",
      account_id: 1
    }
  end

  def debit_factory do
    %Amount{
      amount: Decimal.new(125_000.00),
      type: "debit",
      account_id: 2
    }
  end

  def generate_rand_string() do
    Enum.reduce(1..16, [], fn _i, acc ->
      [Enum.random(@chars) | acc]
    end)
    |> Enum.join("")
  end
end
