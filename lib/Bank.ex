defmodule SoftBank do
  @moduledoc """
  The Main Interface for the Application
  """

  alias SoftBank.Accountant.Supervisor, as: SUPERVISOR
  alias SoftBank.Accountant, as: ACCOUNTANT

  defdelegate transfer(amount, from_account_struct, to_account_struct), to: ACCOUNTANT

  defdelegate withdrawl(amount, from_account_number), to: ACCOUNTANT

  defdelegate deposit(amount, to_account_number), to: ACCOUNTANT

  defdelegate convert(amount, dest_currency), to: ACCOUNTANT

  defdelegate balance(account_number), to: ACCOUNTANT

  @doc """
  Login to the account
  This will start a genserver to act as an accountant to abstract transactions, accountants auto shutdown after a ttl.
  """
  def login(account_number) do
    SUPERVISOR.start_child(account_number)
  end

  def show(account_number) do
    ACCOUNTANT.show_state(account_number)
  end

  @doc """
  Create a new account
  """
  def create(name) do
    SoftBank.Account.new(name)
  end

  @doc """
  Add a currency to the db and load into the ledger system
  """
  def add_currency(params) do
    SoftBank.Currencies.new(params)
  end
end
