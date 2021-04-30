defmodule SoftBank.Accountant do
  use GenServer
  require Logger

  @registry_name :soft_bank_accountants

  @timeout 120
  @ten_seconds 10000
  @fourty_seconds 400_000

  @moduledoc false

  alias SoftBank.Transfer
  alias SoftBank.Account
  alias SoftBank.Amount
  alias SoftBank.Entry

  alias SoftBank.Repo

  defstruct account_number: nil,
            account: nil,
            balance: 0,
            last_action_ts: nil

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
      type: :worker
    }
  end

  def start_link(_) do
    params = %SoftBank.Accountant{account: 0, balance: 0, account_number: nil}
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
    reload(to)
  end

  def withdrawl(amount, from) do
    name = via_tuple(from)
    GenServer.call(name, {:withdrawl, amount, from})
    reload(from)
  end

  def convert(account, amount, to) do
    name = via_tuple(account)
    GenServer.call(name, {:convert, amount, to})
  end

  def balance(account) do
    name = via_tuple(account)
    GenServer.call(name, {:balance, account})
  end

  def transfer(amount, from, to) do
    name = via_tuple(from)
    GenServer.call(name, {:transfer, amount, to})
    reload(from)
  end

  def handle_info(:timeout, state) do
    time = DateTime.utc_now()
    cmp = DateTime.add(state.last_action_ts, @timeout, :second)

    case DateTime.compare(time, cmp) do
      :gt -> Process.send_after(self(), :shutdown, @ten_seconds)
      _ -> Process.send_after(self(), :timeout, @fourty_seconds)
    end

    {:noreply, state}
  end

  def handle_call(:shutdown, _, _) do
    {:stop, :normal, nil, nil}
  end

  def handle_cast(:shutdown, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:transfer, account_number}, state) do
    dest = Account.fetch(%{account_number: account_number, type: "asset"})
    Transfer.send(state.account, dest)
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:noreply, state}
  end

  def handle_call({:withdrawl, amount}, _from, state) do
    decimal = Decimal.negative?(amount.amount)
    new_amount = Money.new(amount.type, decimal)

    IO.inspect(decimal, label: "SoftBank.Accountant.withdrawl")

    entry_changeset = %Entry{
      description: "Withdraw : " <> decimal <> " from " <> state.account.account_number,
      date: DateTime.utc_now(),
      amounts: [
        %Amount{amount: new_amount, type: "debit", account_id: state.account.id}
      ]
    }

    Repo.insert(entry_changeset)

    state = %{state | last_action_ts: DateTime.utc_now()}
    {:reply, state, state}
  end

  def handle_call({:deposit, amount}, _from, state) do
    IO.inspect(amount.amount, label: "SoftBank.Accountant.deposit")

    entry_changeset = %Entry{
      description: "deposit : " <> amount.amount <> " into " <> state.account.account_number,
      date: DateTime.utc_now(),
      amounts: [
        %Amount{amount: amount, type: "debit", account_id: state.account.id}
      ]
    }

    Repo.insert(entry_changeset)
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:reply, state, state}
  end

  def handle_call({:convert, amount, dest_currency}, _from, state) do
    IO.inspect(amount.amount, label: "SoftBank.Accountant.convert")
    Money.to_currency(amount.amount, dest_currency, Money.ExchangeRates.latest_rates())
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:reply, amount.amount, state}
  end

  def handle_call(:balance, _from, state) do
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:reply, state.balance, state}
  end

  def handle_call({:login, account_number}, _from, state) do
    accounts = Account.fetch(%{account_number: account_number})

    {status, state} =
      case Enum.count(accounts) > 0 do
        false ->
          {:error, state}

        true ->
          account = List.first(accounts)

          ### get the balance
          changeset = SoftBank.Account.to_changeset(%SoftBank.Account{}, account)
          changestruct = Ecto.Changeset.apply_changes(changeset)

          balance = Account.account_balance(SoftBank.Repo, changestruct)

          updated_state = %{
            state
            | account_number: account_number,
              account: account,
              balance: balance,
              last_action_ts: DateTime.utc_now()
          }

          {:ok, updated_state}
      end

    Process.send_after(self(), :timeout, @fourty_seconds)
    {:reply, status, state}
  end

  def handle_call({:relogin, account_number}, _from, state) do
    accounts = Account.fetch(%{account_number: account_number})

    {status, state} =
      case Enum.count(accounts) > 0 do
        false ->
          {:error, state}

        true ->
          account = List.first(accounts)

          changeset = SoftBank.Account.to_changeset(%SoftBank.Account{}, account)
          changestruct = Ecto.Changeset.apply_changes(changeset)

          balance = Account.account_balance(Softbank.Repo, changestruct)

          updated_state = %{
            state
            | account_number: account_number,
              account: account,
              balance: balance,
              last_action_ts: DateTime.utc_now()
          }

          {:ok, updated_state}
      end

    {:reply, status, state}
  end

  def handle_call(:show_state, _from, state) do
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:reply, state, state}
  end

  @doc false
  def via_tuple(hash, registry \\ @registry_name) do
    {:via, Registry, {registry, hash}}
  end

  def show_state(account) do
    name = via_tuple(account)
    GenServer.call(name, :show_state)
  end

  def reload(account_number) do
    Process.send_after(self(), 5000, {:relogin, account_number})
  end
end
