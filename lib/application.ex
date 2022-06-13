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

    Supervisor.start_link(children, opts)
    |> check_db_tables()
  end

  defp check_db_tables(response = {:ok, _reply}) do
    Enum.each([SoftBank.Amount, SoftBank.Account, SoftBank.Entry, SoftBank.Currencies], fn x ->
      if SoftBank.Repo.exists?(x) == false do
        raise("The Database Table(s) Do Not Exist")
      end
    end)

    response
  end

  defp check_db_tables(response) do
    response
  end
end
