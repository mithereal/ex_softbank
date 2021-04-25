defmodule SoftBank.Accountant do
  use GenServer
  require Logger

  @registry_name :soft_bank_accountants
  @name __MODULE__

  @moduledoc """
  A Bank Accountant.
  """

  alias SoftBank.Transfer
  alias SoftBank.Account
  alias SoftBank.Amount
  alias SoftBank.Entry
  alias SoftBank.Note
  alias SoftBank.Repo

  defstruct account_number: nil,
            account: nil,
            balance: 0

  @doc false
  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
      type: :worker
    }
  end

  def start_link(args) do

    params = [%{account: 0, balance: 0, account_number: nil}]

    {status, pid} = GenServer.start_link(__MODULE__, params)

case args == nil  do
   false ->
   args = case status  do
    :ok ->
      {status,reply} = GenServer.call pid,{:login, args.account_number}

      case reply do
        nil ->{:stop, :normal, nil, nil}
               _ -> {status,reply}
      end

    :error -> {status, pid}
  end
  true -> {status, pid}
  end
  end

  def init(args) do
    {:ok, args}
  end

  def handle_cast({:deposit}, state) do
    {:noreply, state}
  end

  def handle_cast({:transfer, account_number}, state) do
    dest = Account.fetch(%{account_number: account_number, type: "asset"})
    Transfer.send(state.account, dest)
    {:noreply, state}
  end

  def handle_call({:withdrawl, amount}, _from, state) do
    entry_changeset = %Entry{
      description: "Withdraw : " <> amount.amount <> " from " <> state.account.account_number,
      date: DateTime.utc_now(),
      amounts: [
        %Amount{amount: Note.neg(amount), type: "debit", account_id: state.account.id}
      ]
    }

    Repo.insert(entry_changeset)
    {:reply, state, state}
  end

  def handle_call({:deposit, amount}, _from, state) do
    entry_changeset = %Entry{
      description: "deposit : " <> amount.amount <> " into " <> state.account.account_number,
      date: DateTime.utc_now(),
      amounts: [
        %Amount{amount: amount, type: "debit", account_id: state.account.id}
      ]
    }

    Repo.insert(entry_changeset)
    {:reply, state, state}
  end

  def handle_call({:convert, amount, dest_currency}, _from, state) do
    amount = SoftBank.Currency.Conversion.convert(amount, dest_currency)
    {:reply, amount, state}
  end

  def handle_call(:balance, _from, state) do
    {:reply, state.balance, state}
  end

  def handle_call({:login, account_number}, _from, state) do
    accounts = Account.fetch(%{account_number: account_number, type: "asset"})

    case Enum.count(accounts) do
      0 -> {:reply, nil, state}
      _ ->
      account = List.first(accounts)
      balance = account.balance()

    updated_state =
      updated_state = %__MODULE__{
        state
        | account_number: account_number,
          account: account,
          balance: balance
      }

    {:reply, :ok, updated_state}
    end
  end

  def handle_call(:show_state, _from, state) do
    {:reply, state, state}
  end

    @doc false
  def via_tuple(hash, registry \\ @registry_name) do
    {:via, Registry, {registry, hash}}
  end

  def show_state(data) do
      name = via_tuple(data.hash)

    GenServer.start_link(__MODULE__, [data], name: name)
  end
end
