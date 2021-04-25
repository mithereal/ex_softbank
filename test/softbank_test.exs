defmodule SoftBankTest do
  use ExUnit.Case
  use SoftBank.EctoCase
  alias SoftBank.Account
  alias SoftBank.TestRepo, as: REPO

  #    doctest SoftBank
  #  doctest SoftBank.Account

  test "Create a new Account" do
    data = SoftBank.create()
    assert data !== nil
  end

  test "Login to the bank account (success)" do
    query = from(Account)
    accounts = REPO.all(query)
    account = List.first(accounts)

    data = SoftBank.login(account.bank_account_number)
    assert data.bank_account_number == account.bank_account_number
  end

  test "Login to the bank account(failure)" do
    bank_account_number = "339571873745"
    data = SoftBank.login(bank_account_number)
    assert data == nil
  end
end
