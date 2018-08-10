defmodule SoftBank.Teller do
  require Logger

  use GenServer

  @name __MODULE__
  @moduledoc """
  A Bank Teller.
  """

  alias SoftBank.Transfer
  alias SoftBank.Account
  alias SoftBank.Amount
  alias SoftBank.Entry
  alias SoftBank.Note


  defstruct ban: nil,
            account: nil,
            balance: 0


  def start_link() do

    state = %{ account: 0, balance: 0, ban: nil }

    GenServer.start_link(__MODULE__, [state])
  end


  def handle_cast({:deposit},  state) do

    {:noreply, state}
  end

  def handle_cast({:transfer, dest_ban},  state) do
    dest = Account.fetch(%{ban: dest_ban, type: "asset"})
    Transfer.send(state.account, dest)
    {:noreply, state}
  end


  def handle_call({:withdrawl, amount}, _from,  state) do
    entry_changeset = %Entry{
      description: "Withdraw : " <> amount.amount <> " from " <> state.account.ban,
      date: Ecto.Date.utc(),
      amounts: [
        %Amount{ amount: Note.neg(amount), type: "debit", account_id: state.account.id }]
    }

    Repo.insert(entry_changeset)
    {:reply, state, state}
  end

  def handle_call({:deposit, amount}, _from,  state) do
    entry_changeset = %Entry{
      description: "deposit : " <> amount.amount <> " into " <> state.account.ban,
      date: Ecto.Date.utc(),
      amounts: [
        %Amount{ amount: amount, type: "debit", account_id: state.account.id }]
    }

    Repo.insert(entry_changeset)
    {:reply, state, state}
  end


  def handle_call({:convert, amount, dest_currency}, _from,  state) do
    amount = SoftBank.Currency.Conversion.convert(amount, dest_currency)
    {:reply, amount, state}
  end

  def handle_call({:balance, account_number}, _from,  state) do
    {:reply, state.balance, state}
  end

  def handle_call({:login, ban}, _from,  state) do
    account = Account.fetch(%{ban: ban, type: "asset"})
    balance = account.balance()
    updated_state = updated_state = %__MODULE__{ state |  ban: ban, account: account, balance: balance }
    {:reply, :ok, updated_state}
  end

  def handle_call(:show_state, _from,  state) do

    {:reply, state, state}
  end

end
