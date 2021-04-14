defmodule SoftBank.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # List all child processes to be supervised
    children = [
      supervisor(SoftBank.Repo, [])
      # Starts a worker by calling: SoftBank.Worker.start_link(arg)
      # {SoftBank.Worker, arg},
      # worker(SoftBank.Currency.Conversion.UpdateWorker, [], restart: :permanent)
      # worker(Task, [&load/0], restart: :transient)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [
      strategy: :one_for_one,
      name: SoftBank.Tellers.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
