defmodule SoftBank do

  @moduledoc false

  alias SoftBank.Accountant.Supervisor

  def transfer(destination_account_number) do
    Supervisor.transfer(destination_account_number)
  end

  def withdrawl(amount) do
     Supervisor.withdrawl(amount)
  end

  def deposit(amount) do
     Supervisor.deposit(amount)
  end

  def convert(amount, dest_currency) do
     Supervisor.convert(amount, dest_currency)
  end

  def balance(account_number) do
     Supervisor.balance(account_number)
  end

  def login(account_number) do
  params = %{account: 0, balance: 0, account_number: account_number}
  {status, pid} = Supervisor.start_child(params, true)

  case status do
    :ok ->
    case Supervisor.exists? account_number do
      nil -> {:error, "INVALID ACCOUNT NUMBER"}
      _ ->  SoftBank.Accountant.show_state account_number
    end

    :error -> {status, "AN ERROR OCCURRED"}
  end

  end



  def show(account_number) do
     Supervisor.show(account_number)
  end
end
