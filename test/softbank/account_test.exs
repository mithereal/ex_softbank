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
    owner = insert(:owner)
    asset = insert(:account, owner: owner)
    insert(:account, name: "Liabilities", type: "liability", owner: owner)
    insert(:account, name: "Revenue", type: "asset", owner: owner)
    insert(:account, name: "Expense", type: "asset", owner: owner)
    equity = insert(:account, name: "Equity", type: "equity", owner: owner)
    drawing = insert(:account, name: "Drawing", type: "equity", contra: true, owner: owner)

    result = Account.test_balance(TestRepo)

    assert result == Money.new(:USD, 0)

    insert(:entry,
      amounts: [build(:credit, account_id: asset.id), build(:debit, account_id: equity.id)]
    )

    assert Money.to_string!(Account.test_balance(TestRepo), locale: "en") == "$0.00"

    insert(:entry,
      amounts: [build(:credit, account_id: equity.id), build(:debit, account_id: drawing.id)]
    )

    assert Money.to_string!(Account.test_balance(TestRepo), locale: "en") == "$0.00"

    insert(:entry, amounts: [build(:credit, account_id: asset.id)])

    refute Money.to_string!(Account.test_balance(TestRepo), locale: "en") == "$0.00"
  end

  test "account balances with entries and dates" do
    owner = insert(:owner)
    insert(:account, owner: owner)
    insert(:account, name: "Liabilities", type: "liability", owner: owner)
    insert(:account, name: "Revenue", type: "asset", owner: owner)
    insert(:account, name: "Expense", type: "asset", owner: owner)
    equity = insert(:account, name: "Equity", type: "equity", owner: owner)
    drawing = insert(:account, name: "Drawing", type: "equity", contra: true, owner: owner)

    insert(:entry,
      amounts: [build(:credit, account_id: equity.id), build(:debit, account_id: drawing.id)]
    )

    assert Account.account_balance(TestRepo, equity) ==
             Account.balance(TestRepo, equity, %{
               to_date: DateTime.utc_now()
             })

    insert(:entry,
      date: DateTime.utc_now(),
      amounts: [build(:credit, account_id: equity.id), build(:debit, account_id: drawing.id)]
    )

    assert Account.account_balance(TestRepo, equity) ==
             Account.balance(TestRepo, equity, %{
               to_date: DateTime.utc_now()
             })
  end
end
