defmodule SoftBank.Application do
  @moduledoc false

  use Application

  def start(_type, args) do
	  env =
		  case Mix.env() == :test do
			  true -> [{SoftBank.TestRepo, args}]
			  false -> []
		  end

	  children = [
      {Cldr.Currency, [callback: {SoftBank.Currencies, :init, []}]},
      {Registry, keys: :unique, name: :soft_bank_accounts},
      {SoftBank.ExchangeRates.Supervisor, [restart: true, start_retriever: true]},
      {SoftBank.Currency.Reload, name: SoftBank.Currency.Reload},
      {DynamicSupervisor, strategy: :one_for_one, name: SoftBank.Accountant.Supervisor}
    ] ++ env

    opts = [
      strategy: :one_for_one,
      name: SoftBank.Supervisor
    ]

    case Enum.member?([:dev, :test], Application.get_env(:soft_bank, :env, :dev)) do
      false ->
        Supervisor.start_link(children, opts)
        |> check_db_tables()

      true ->
        Supervisor.start_link(children, opts)
    end
  end

  defp check_db_tables(response = {:ok, _reply}) do
    Enum.each([SoftBank.Amount, SoftBank.Account, SoftBank.Entry, SoftBank.Currencies], fn x ->
      try do
        config = SoftBank.Config.new()

        if SoftBank.Repo.exists?(config, x) == false do
          raise("Unable To Read Database Table(s)")
        end
      rescue
        _ ->
          raise("Unable To Read Database Table(s)")
      end
    end)

    response
  end

  defp check_db_tables(response) do
    response
  end
end
