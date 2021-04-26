defmodule SoftBank.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, args) do
    import Supervisor.Spec

    # List all child processes to be supervised
    children = [
      {SoftBank.Repo, args},
      # Cldr.Currency,
      {Cldr.Currency, [callback: {SoftBank.Currencies, :init, []}]},
      {Registry, keys: :unique, name: :soft_bank_accountants},
      # Starts a worker by calling: SoftBank.Worker.start_link(arg)
      # {SoftBank.Worker, args},
      supervisor(Money.ExchangeRates.Supervisor, [[restart: true, start_retriever: true]]),
      {SoftBank.Currency.Reload, name: SoftBank.Currency.Reload},
      {DynamicSupervisor, strategy: :one_for_one, name: SoftBank.Accountant.Supervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [
      strategy: :one_for_one,
      name: SoftBank.Supervisor
    ]

    {status, reply} = Supervisor.start_link(children, opts)

    case status do
      :ok ->
        tables_exist = check_db_tables()

        {status, reply}

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
