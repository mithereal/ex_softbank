defmodule SoftBank.Accountant do
  use GenServer
  require Logger

  @registry_name :soft_bank_accounts

  @moduledoc false

  alias SoftBank.Transfer
  alias SoftBank.Account
  alias SoftBank.Amount
  alias SoftBank.Entry

  alias SoftBank.Repo

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
      type: :worker
    }
  end

  def start_link(params \\ []) do
    data = Account.fetch(%{account_number: params.account_number}, Repo)
    name = via_tuple(params.account_number)
    GenServer.start_link(__MODULE__, data, name: name)
  end

  @impl true
  def init(args) do
    ref =
      :ets.new(String.to_atom(args.hash), [
        :set,
        :named_table,
        :public,
        read_concurrency: true,
        write_concurrency: true
      ])

    :ets.insert(ref, {:account, args})

    {:ok, %{ref: ref}}
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
    {:noreply, state}
  end

  def handle_call({:transfer, account_number, amount}, _, state) do
    destination_account = Account.fetch(%{account_number: account_number, type: "asset"})
    params = %{amount: amount}
    reply = Transfer.send(state.account, destination_account, params)
    {:reply, reply, state}
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

    reply = Repo.insert(changeset)

    {:reply, reply, state}
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

    reply = Repo.insert(changeset)

    {:reply, reply, state}
  end

  def handle_call({:convert, amount, dest_currency}, _from, state) do
    rates = Money.ExchangeRates.latest_rates()
    new_amount = Money.to_currency(amount, dest_currency, rates)
    {:reply, new_amount, state}
  end

  def handle_call(:balance, _from, state) do
    reply = :ets.lookup(state.ref, :account)
    {:reply, reply, state}
  end

  def handle_call(:show, _from, state) do
    reply = :ets.lookup(state.ref, :account)
    {:reply, reply, state}
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
