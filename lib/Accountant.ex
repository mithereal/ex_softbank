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

  def start_link(account_number) do
    name = via_tuple(account_number)
    params = %SoftBank.Accountant{account: 0, balance: 0, account_number: account_number}
    GenServer.start_link(__MODULE__, params, name: name)
  end

  @impl true
  def init(args) do
    name = via_tuple(args.account_number)

    GenServer.cast(name, :login)

    {:ok, args}
  end

  def shutdown(pid) do
    GenServer.call(pid, :shutdown)
  end

  def deposit(amount, to, currency \\ :USD) do
    name = via_tuple(to)
    amount = Money.new!(currency, amount)
         try do
           GenServer.call(name, {:deposit, amount})
            GenServer.call(name, {:relogin, to})
    catch
      :exit, _ -> {:error, "invalid_account"}
    end

  end

  def withdrawl(amount, from, currency \\ :USD) do
    name = via_tuple(from)
    amount = Money.new!(currency, amount)
     try do
           GenServer.call(name, {:withdrawl, amount})
           GenServer.call(name, {:relogin, from})
    catch
      :exit, _ -> {:error, "invalid_account"}
    end

  end

  def convert(amount, dest_currency) do
    latest_rates = Money.ExchangeRates.latest_rates()

    rates =
      case(latest_rates) do
        {:error, rates} -> []
        {:ok, rates} -> rates
      end

    Money.to_currency(amount, dest_currency, rates)
  end

  def balance(account) do
    name = via_tuple(account)
      try do
          GenServer.call(name, :balance)
    catch
      :exit, _ -> {:error, "invalid_account"}
    end

  end

  def transfer(amount, from, to) do
    name = via_tuple(from)
      try do
          GenServer.call(name, {:transfer, to, amount})
          GenServer.call(name, {:relogin, from})
    catch
      :exit, _ -> {:error, "invalid_account"}
    end

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

  def handle_cast({:transfer, account_number, amount}, state) do
    destination_account = Account.fetch(%{account_number: account_number, type: "asset"})
    params = %{amount: amount}
    Transfer.send(state.account, destination_account, params)
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:noreply, state}
  end

  def handle_call({:transfer, account_number, amount},_, state) do
    destination_account = Account.fetch(%{account_number: account_number, type: "asset"})
    params = %{amount: amount}
    Transfer.send(state.account, destination_account, params)
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:reply, :ok, state}
  end

  def handle_call({:withdrawl, amount}, _from, state) do
    type = amount.currency()

    changeset =
      Entry.changeset(%Entry{
        description:
          "Withdrawl : " <>
            to_string(amount) <> " from " <> to_string(state.account.account_number),
        date: DateTime.utc_now(),
        amounts: [
          %Amount{amount: amount, type: "credit", account_id: state.account.id},
          %Amount{amount: amount, type: "debit", account_id: state.account.id}
        ]
      })

    Repo.insert(changeset)

    state = %{state | last_action_ts: DateTime.utc_now()}
    {:reply, state, state}
  end

  def handle_call({:deposit, amount}, _from, state) do
    type = amount.currency()

    changeset =
      Entry.changeset(%Entry{
        description:
          "deposit : " <> to_string(amount) <> " into " <> to_string(state.account_number),
        ## remove microseconds
        date: DateTime.utc_now(),
        amounts: [
          %Amount{amount: amount, type: "debit", account_id: state.account.id},
          %Amount{amount: amount, type: "credit", account_id: state.account.id}
        ]
      })

    Repo.insert(changeset)
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:reply, state, state}
  end

  def handle_call({:convert, amount, dest_currency}, _from, state) do
    IO.inspect(amount.amount, label: "SoftBank.Accountant.convert")
    rates = Money.ExchangeRates.latest_rates()
    rates = []
    new_amount = Money.to_currency(amount, dest_currency, rates)
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:reply, new_amount, state}
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

          {_, balance} = Account.account_balance(SoftBank.Repo, changestruct)

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

  def handle_cast(:login, state) do
    account = Account.fetch(%{account_number: state.account_number})

    changeset = SoftBank.Account.to_changeset(%SoftBank.Account{}, account)

    changestruct = Ecto.Changeset.apply_changes(changeset)

    {_, balance} = Account.account_balance(SoftBank.Repo, changestruct)

    updated_state = %{
      state
      | account_number: state.account_number,
        account: account,
        balance: balance,
        last_action_ts: DateTime.utc_now()
    }

    Process.send_after(self(), :timeout, @fourty_seconds)

    {:noreply, updated_state}
  end

  def handle_call({:relogin, account_number},  _, state) do
    account = Account.fetch(%{account_number: account_number})

    {status, state} =
      case Enum.count(account) > 0 do
        false ->
          {:error, state}

        true ->

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
      try do
          GenServer.call(name, :show_state)
    catch
      :exit, _ -> {:error, "invalid_account"}
    end

  end

end
