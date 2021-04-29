defmodule SoftBank.EntryTest do
  use SoftBank.EctoCase

  import SoftBank.TestFactory
  alias SoftBank.{Amount, Entry}

  @valid_attrs params_for(:entry)
  @invalid_attrs %{}
  @test_amount  Money.new!(:USD, "125,000.00")
  @test_amount_alt  Money.new!(:USD, "225,000.00")
  @valid_with_amount_attrs %{
    description: "Spending Money",
    date: DateTime.utc_now(),
    amounts: [
      %Amount{amount: @test_amount, type: "credit", account_id: 1},
      %Amount{amount: @test_amount, type: "debit", account_id: 2}
    ]
  }

  test "entry casts associated amounts" do

    changeset =
      Entry.changeset(%Entry{
        description: "Spending Money Again",
        date: DateTime.utc_now(),
        amounts: [
          %Amount{amount: @test_amount, type: "credit", account_id: 2},
          %Amount{amount: @test_amount, type: "debit", account_id: 1},
          %Amount{amount: @test_amount, type: "debit", account_id: 1}
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
          %Amount{amount: @test_amount_alt, type: "credit", account_id: 2},
          %Amount{amount: @test_amount, type: "debit", account_id: 1},
          %Amount{amount: @test_amount_alt, type: "debit", account_id: 1}
        ]
      })

    refute changeset.valid?
  end
end
