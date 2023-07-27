defmodule SoftBank.AccountTest do
  use SoftBank.EctoCase

  :ok = Ecto.Adapters.SQL.Sandbox.checkout(SoftBank.TestRepo)

  import SoftBank.TestFactory
  alias SoftBank.{Account, TestRepo, Accountant}

  test "check the account balance via an accountant/ets" do
    owner = Owner.new("demo")

    SoftBank.login(owner.owner.account_number)
    Accountant.balance(owner.owner.account_number)
  end
end
