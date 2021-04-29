defmodule SoftBank.AccountTest do
  use SoftBank.EctoCase

  :ok = Ecto.Adapters.SQL.Sandbox.checkout(SoftBank.TestRepo)

  import SoftBank.TestFactory
  alias SoftBank.{Account, TestRepo}

  @valid_attrs params_for(:account)
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Account.changeset(%Account{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Account.changeset(%Account{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "test balance zero with and without entries" do
    asset = insert(:account)
    insert(:account, name: "Liabilities", type: "liability")
    insert(:account, name: "Revenue", type: "asset")
    insert(:account, name: "Expense", type: "asset")
    equity = insert(:account, name: "Equity", type: "equity")
    drawing = insert(:account, name: "Drawing", type: "equity", contra: true)


    assert Account.test_balance(TestRepo) == Money.new(:USD, 0)

    insert(:entry,
      amounts: [build(:credit, account_id: asset.id), build(:debit, account_id: equity.id)]
    )

    assert Decimal.to_integer(Account.starting_balance(TestRepo)) == 0

    insert(:entry,
      amounts: [build(:credit, account_id: equity.id), build(:debit, account_id: drawing.id)]
    )

    assert Decimal.to_integer(Account.starting_balance(TestRepo)) == 0

    insert(:entry, amounts: [build(:credit, account_id: asset.id)])

    refute Decimal.to_integer(Account.starting_balance(TestRepo)) == 0
  end

  test "account balances with entries and dates" do
    insert(:account)
    insert(:account, name: "Liabilities", type: "liability")
    insert(:account, name: "Revenue", type: "asset")
    insert(:account, name: "Expense", type: "asset")
    equity = insert(:account, name: "Equity", type: "equity")
    drawing = insert(:account, name: "Drawing", type: "equity", contra: true)

    insert(:entry,
      amounts: [build(:credit, account_id: equity.id), build(:debit, account_id: drawing.id)]
    )

#    assert Account.account_balance(TestRepo, equity) ==
#             Account.balance(TestRepo, equity, %{
#               to_date: DateTime.utc_now()
#             })
#
#    insert(:entry,
#      date: DateTime.utc_now(),
#      amounts: [build(:credit, account_id: equity.id), build(:debit, account_id: drawing.id)]
#    )
#
#    refute Account.balance(TestRepo, equity) ==
#             Account.account_balance(TestRepo, equity, %{
#               to_date: DateTime.utc_now()
#             })
#
#    assert Account.balance(TestRepo, equity) ==
#             Account.account_balance(TestRepo, equity, %{
#               to_date: DateTime.utc_now()
#             })
#
#    refute Account.balance(TestRepo, equity) ==
#             Account.account_balance(TestRepo, equity, %{
#               to_date: DateTime.utc_now()
#             })
  end
end
