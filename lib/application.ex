defmodule SoftBank.Application do
  @moduledoc false

  use Application

  def start(_type, args) do
    import Supervisor.Spec

    children = [
      {SoftBank.Repo, args},
      {Cldr.Currency, [callback: {SoftBank.Currencies, :init, []}]},
      {Registry, keys: :unique, name: :soft_bank_accountants},
      supervisor(Money.ExchangeRates.Supervisor, [[restart: true, start_retriever: true]]),
      {SoftBank.Currency.Reload, name: SoftBank.Currency.Reload},
      {DynamicSupervisor, strategy: :one_for_one, name: SoftBank.Accountant.Supervisor}
    ]

    opts = [
      strategy: :one_for_one,
      name: SoftBank.Supervisor
    ]

    {status, reply} = Supervisor.start_link(children, opts)

    case status do
      :ok ->
        case check_db_tables() do
          false -> {:error, "The Database Table(s) Do Not Exist"}
          true -> {:ok, reply}
        end

      :error ->
        {status, reply}
    end
  end

  def check_db_tables() do
    tb1 = SoftBank.Repo.exists?(SoftBank.Amount)
    tb2 = SoftBank.Repo.exists?(SoftBank.Account)
    tb3 = SoftBank.Repo.exists?(SoftBank.Entry)
    tb1 == tb2 == tb3 == true
  end
end
