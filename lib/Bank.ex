defmodule SoftBank do
  use GenServer
  @moduledoc """
  The Main Interface for the Application
  """
  @registry_name :soft_bank_accountants

  alias SoftBank.Accountant.Supervisor, as: SUPERVISOR
  alias SoftBank.Accountant, as: ACCOUNTANT

  defdelegate transfer(amount, from_account_number, to_account_number), to: ACCOUNTANT

  defdelegate withdrawl(amount, from_account_number), to: ACCOUNTANT

  defdelegate deposit(amount, to_account_number) , to: ACCOUNTANT

  defdelegate convert(account_number, amount, dest_currency), to: ACCOUNTANT

  defdelegate balance(account_number), to: ACCOUNTANT

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

  @doc false
  def via_tuple(hash, registry \\ @registry_name) do
    {:via, Registry, {registry, hash}}
  end
end
