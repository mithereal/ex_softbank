defmodule SoftBank.ExchangeRates.Supervisor do
  use DynamicSupervisor

  @name __MODULE__

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {Money.ExchangeRates.Supervisor, :start_link, [args]},
      type: :supervisor
    }
  end

  def init(args) do
    try do
      DynamicSupervisor.init(
        strategy: :one_for_one,
        extra_arguments: args
      )
    rescue
      _ -> throw("anerror occured")
    end
  end
end
