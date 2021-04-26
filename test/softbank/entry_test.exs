defmodule SoftBank.EntryTest do
  use SoftBank.EctoCase

  import SoftBank.TestFactory
  alias SoftBank.{Amount, Entry}

  @valid_attrs params_for(:entry)
  @invalid_attrs %{}

  @valid_with_amount_attrs %{
    description: "Spending Money",
    date: DateTime.utc_now(),
    amounts: [
      %Amount{amount: Money.new(:USD, "125,000.00"), type: "credit", account_id: 1},
      %Amount{amount: Money.new(:USD, "125,000.00"), type: "debit", account_id: 2}
    ]
  }

  test "entry casts associated amounts" do
    changeset =
      Entry.changeset(%Entry{
        description: "Spending Money Again",
        date: DateTime.utc_now(),
        amounts: [
          %Amount{amount: Money.new(:USD, "125,000.00"), type: "credit", account_id: 2},
          %Amount{amount: Money.new(:USD, "125,_000.00"), type: "debit", account_id: 1},
          %Amount{amount: Money.new(:USD, "125,000.00"), type: "debit", account_id: 1}
        ]
      })

    assert changeset.valid?
  end

  test "entry debits and credits must cancel" do
    changeset =
      Entry.changeset(%Entry{
        description: "Spending Lots More Money",
        date: DateTime.utc_now(),
        amounts: [
          %Amount{amount: Money.new(:USD, "25,000.00"), type: "credit", account_id: 2},
          %Amount{amount: Money.new(:USD, "55,000.00"), type: "debit", account_id: 1},
          %Amount{amount: Money.new(:USD, "125,000.00"), type: "debit", account_id: 1}
        ]
      })

    refute changeset.valid?
  end
end
