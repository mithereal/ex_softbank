defmodule SoftBank.Tellers.Supervisor do
  use Supervisor

  @pool_name :soft_bank_tellers

  alias SoftBank.Config

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start() do
    Supervisor.start_child(__MODULE__, [])
  end


  def stop(id) do

        Process.exit(id, :shutdown)
        :ok

  end

  def init([]) do
    # Here are my pool options
    pool_options = [
      name: {:local, @pool_name},
      worker_module: SoftBank.Teller,
      size: Config.get(:pool_size, 10),
      max_overflow: Config.get(:pool_max_overflow, 1)
    ]

    children = [
      :poolboy.child_spec(@pool_name, pool_options, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def call(args) do
    #:poolboy.transaction(@pool_name, fn(worker) -> GenServer.call(worker, %{command: :query, params: args}) end, Config.get(:timeout, 5000))
  end
end
