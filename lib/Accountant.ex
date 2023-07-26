defmodule SoftBank.Accountant do
  use GenServer
  require Logger

  @registry_name :soft_bank_accountants

  @moduledoc false

  alias SoftBank.Transfer
  alias SoftBank.Account
  alias SoftBank.Amount
  alias SoftBank.Entry

  alias SoftBank.Repo

  defstruct account_number: nil

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
      type: :worker
    }
  end

  def start_link(account_number) do
    name = via_tuple(account_number)
    GenServer.start_link(__MODULE__, params, name: name)
  end

  @impl true
  def init(args) do
    ref =
      :ets.new(String.to_atom(args.account_number), [
        :set,
        :named_table,
        :public,
        read_concurrency: true,
        write_concurrency: true
      ])

    :ets.insert(ref, {:default, args})

    {:ok, %{account_number: args.account_number, ref: ref}}
  end

  def shutdown(pid) do
    GenServer.call(pid, :shutdown)
  end

  def deposit(amount, to, currency \\ :USD) do
    name = via_tuple(to)
    amount = Money.new!(currency, amount)

    try do
      GenServer.call(name, {:deposit, amount})
    catch
      :exit, _ -> {:error, "invalid_account"}
    end
  end

  def withdrawl(amount, from, currency \\ :USD) do
    name = via_tuple(from)
    amount = Money.new!(currency, amount)

    try do
      GenServer.call(name, {:withdrawl, amount})
    catch
      :exit, _ -> {:error, "invalid_account"}
    end
  end

  def convert(amount, dest_currency) do
    latest_rates = Money.ExchangeRates.latest_rates()

    rates =
      case(latest_rates) do
        {:error, _rates} -> []
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
    catch
      :exit, _ -> {:error, "invalid_account"}
    end
  end

  @impl true
  def handle_call(
        :shutdown,
        _from,
        state
      ) do
    {:stop, {:ok, "Normal Shutdown"}, state}
  end

  @impl true
  def handle_cast(
        :shutdown,
        state
      ) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, {names, refs}) do
    :ets.delete(names)
    {:noreply, {names, refs}}
  end

  def handle_cast({:transfer, account_number, amount}, state) do
    destination_account = Account.fetch(%{account_number: account_number, type: "asset"})
    params = %{amount: amount}
    Transfer.send(state.account, destination_account, params)
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:noreply, state}
  end

  def handle_call({:transfer, account_number, amount}, _, state) do
    destination_account = Account.fetch(%{account_number: account_number, type: "asset"})
    params = %{amount: amount}
    Transfer.send(state.account, destination_account, params)
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:reply, :ok, state}
  end

  def handle_call({:withdrawl, amount}, _from, state) do
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
    rates = Money.ExchangeRates.latest_rates()
    new_amount = Money.to_currency(amount, dest_currency, rates)
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:reply, new_amount, state}
  end

  def handle_call(:balance, _from, state) do
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:reply, state.balance, state}
  end

  def handle_call(:show, _from, state) do
    state = %{state | last_action_ts: DateTime.utc_now()}
    {:reply, state, state}
  end

  @doc false
  def via_tuple(hash, registry \\ @registry_name) do
    {:via, Registry, {registry, hash}}
  end

  def show(account) do
    name = via_tuple(account)

    try do
      GenServer.call(name, :show)
    catch
      :exit, _ -> {:error, "invalid_account"}
    end
  end
end
