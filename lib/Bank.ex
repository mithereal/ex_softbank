defmodule SoftBank do
  @moduledoc """
  The Main Interface for the Application
  """

  alias SoftBank.Accountant.Supervisor, as: SUPERVISOR
  alias SoftBank.Accountant, as: ACCOUNTANT

  @doc """
  Transfer an amount from an account number to another account number
  """
  def transfer(amount, from_account_number, to_account_number) do
    ACCOUNTANT.transfer(amount, from_account_number, to_account_number)
  end

  @doc """
  Withdrawl an amount from an account number
  """
  def withdrawl(amount, from_account_number) do
    ACCOUNTANT.withdrawl(amount, from_account_number)
  end

  @doc """
  Deposit an amount to an account number
  """
  def deposit(amount, to_account_number) do
    ACCOUNTANT.deposit(amount, to_account_number)
  end

  @doc """
  Convert an amount between currencies
  """
  def convert(account_number, amount, dest_currency) do
    ACCOUNTANT.convert(account_number, amount, dest_currency)
  end

  @doc """
  Return the account balance
  """
  def balance(account_number) do
    ACCOUNTANT.balance(account_number)
  end

  @doc """
  Login to the account
  This will start a genserver to act as an accountant to abstract transactions, accountants auto shutdown after a ttl.
  """
  def login(account_number) do
    {status, pid} = SUPERVISOR.start_child()

    case status do
      :ok ->
        params = %{account: 0, balance: 0, account_number: account_number}
        reply = ACCOUNTANT.try_login(pid, params)

        case reply do
          :ok ->
            Registry.register(:soft_bank_accountants, account_number, pid)
            {:ok, account_number}

          :error ->
            ## stop the accountant
            ACCOUNTANT.shutdown(pid)
            {:error, account_number}
        end

      :error ->
        {status, "AN ERROR OCCURRED"}
    end
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
