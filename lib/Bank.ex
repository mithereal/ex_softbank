defmodule SoftBank do
  @moduledoc false

  alias SoftBank.Accountant.Supervisor, as: SUPERVISOR
  alias SoftBank.Accountant, as: ACCOUNTANT

  def transfer(amount, from_account_number, to_account_number) do
    ACCOUNTANT.transfer(amount, from_account_number, to_account_number)
  end

  def withdrawl(amount, from_account_number) do
    ACCOUNTANT.withdrawl(amount, from_account_number)
  end

  def deposit(amount, to_account_number) do
    ACCOUNTANT.deposit(amount, to_account_number)
  end

  def convert(account_number, amount, dest_currency) do
    ACCOUNTANT.convert(account_number, amount, dest_currency)
  end

  def balance(account_number) do
    ACCOUNTANT.balance(account_number)
  end

  def login(account_number) do
    ## start a new accountant
    {status, pid} = SUPERVISOR.start_child()
    ### login to the account

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

  def create() do
    SoftBank.Account.new()
  end
end
