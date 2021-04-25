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
  {_, pid} = Supervisor.start_child(params)
  GenServer.call pid, :show_state
  end

  def show(account_number) do
     Supervisor.show(account_number)
  end
end
