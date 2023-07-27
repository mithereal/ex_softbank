defmodule SoftBank.AccountTest do
  use SoftBank.EctoCase

  :ok = Ecto.Adapters.SQL.Sandbox.checkout(SoftBank.TestRepo)

  import SoftBank.TestFactory
  alias SoftBank.{Account, TestRepo, Accountant}

  test "check the account balance via an accountant/ets" do
    owner = Owner.new("demo")
		amount =
    SoftBank.login(owner.owner.account_number)
    balance = Accountant.balance(owner.owner.account_number)

    assert Money.new(:USD, "0") == balance
  end
end
