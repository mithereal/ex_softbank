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
#            account: nil,
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

  def try_login(pid, args ) do

  GenServer.call(pid, {:login, args.account_number})

  end

  def init(args) do

    {:ok, args}
  end

  def shutdown(pid) do
      GenServer.call(pid, :shutdown)
  end

  def handle_cast({:deposit}, state) do
    {:noreply, state}
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
    accounts = Account.fetch(%{account_number: account_number})

    case Enum.count(accounts) > 0 do
      false ->
        {:reply, :error, state}

      true ->

       accounts = Enum.map(accounts,fn(x) ->
                                    {x.account_number,x}
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
    {:via, Registry, {registry, hash}}
  end

  def show_state(data) do
    name = via_tuple(data.hash)

    GenServer.start_link(__MODULE__, [data], name: name)
  end
end
