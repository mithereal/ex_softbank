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

  defstruct accounts: []
  #  account_number: nil,
  #            account: nil, %{id:x}
  #            balance: 0

  @doc false
  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
      type: :worker
    }
  end

  def start_link(args) do
    params = [%{accounts: []}]
    GenServer.start_link(__MODULE__, params)
  end

  def try_login(pid, args) do
    GenServer.call(pid, {:login, args.account_number})
  end

  def init(args) do
    {:ok, args}
  end

  def shutdown(pid) do
    GenServer.call(pid, :shutdown)
  end

  def deposit(amount, to) do
    name = via_tuple(to)
    GenServer.call(name, {:deposit, amount, to})
  end

  def withdrawl(amount, from) do
    name = via_tuple(from)
    GenServer.call(name, {:withdrawl, amount, from})
  end

  def convert(account, amount, to) do
    GenServer.call(account, {:convert, amount, to})
  end

  def balance(account) do
    name = via_tuple(account)
    GenServer.call(name, {:balance, account})
  end

  def transfer(amount, from, to) do
    name = via_tuple(from)
    GenServer.call(name, {:transfer, amount, from, to})
  end

  def handle_cast(:shutdown, state) do
    {:stop, :normal, state}
  end

  def handle_call(:shutdown, _, state) do
    {:stop, :normal, nil, nil}
  end

  def handle_cast({:transfer, from_account_number, to_account_number}, state) do
    dest = Account.fetch(%{account_number: to_account_number, type: "asset"})
    Transfer.send(from_account_number, dest)
    {:noreply, state}
  end

  def handle_call({:withdrawl, amount, from}, _from, state) do
    entry_changeset = %Entry{
      description: "Withdraw : " <> amount.amount <> " from " <> from,
      date: DateTime.utc_now(),
      amounts: [
        %Amount{amount: Note.neg(amount), type: "debit", account_id: from}
      ]
    }

    Repo.insert(entry_changeset)
    {:reply, state, state}
  end

  def handle_call({:deposit, amount, to}, _from, state) do
    entry_changeset = %Entry{
      description: "deposit : " <> amount.amount <> " into " <> to,
      date: DateTime.utc_now(),
      amounts: [
        %Amount{amount: amount, type: "debit", account_id: to}
      ]
    }

    Repo.insert(entry_changeset)
    {:reply, state, state}
  end

  def handle_call({:convert, amount, dest_currency}, _from, state) do
    amount = SoftBank.Currency.Conversion.convert(amount, dest_currency)
    {:reply, amount, state}
  end

  def handle_call({:balance, account_number}, _from, state) do
    result = SoftBank.Account.balance(SoftBank.Repo, account_number)
    {:reply, result, state}
  end

  def handle_call({:login, account_number}, _from, state) do
    accounts = Account.fetch(%{account_number: account_number})

    case Enum.count(accounts) > 0 do
      false ->
        {:reply, :error, state}

      true ->
        accounts =
          Enum.map(accounts, fn x ->
            {x.account_number, x}
          end)

        updated_state =
          updated_state = %__MODULE__{
            state
            | accounts: accounts
          }

        {:reply, :ok, updated_state}
    end
  end

  def handle_call(:show_state, _from, state) do
    {:reply, state, state}
  end

  @doc false
  def via_tuple(hash, registry \\ @registry_name) do
    reload(hash)
    {:via, Registry, {registry, hash}}
  end

  def show_state(account) do
    name = via_tuple(account)

    GenServer.start_link(__MODULE__, [account], name: name)
  end

  def reload(account_number) do
    Process.send_after(self(), 1000, {:login, account_number})
  end
end
