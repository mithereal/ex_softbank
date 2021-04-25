defmodule SoftBank.Accountant.Supervisor do
  use DynamicSupervisor

  @registry_name :soft_bank_accountants
  @name __MODULE__

  alias SoftBank.Config

  def child_spec([args]) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, args},
      type: :supervisor
    }
  end

  def start_child(args \\ nil, required \\ false) do
    case required do
      false ->
        spec = {SoftBank.Accountant, args}
        DynamicSupervisor.start_child(__MODULE__, spec)

      true ->
        case String.length(String.trim(args.account_number)) do
          0 ->
            {:error, nil}

          _ ->
            spec = {SoftBank.Accountant, args}
            DynamicSupervisor.start_child(__MODULE__, spec)
        end
    end
  end

  def start_link(args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, args, name: @name)
  end

  def start() do
    start_link()
  end

  def stop(id) do
    Process.exit(id, :shutdown)
    :ok
  end

  def init(args) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: args
    )
  end
end
