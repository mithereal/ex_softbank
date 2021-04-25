defmodule SoftBank.EctoCase do
  use ExUnit.CaseTemplate

  # setup do
  #  :ok = Ecto.Adapters.SQL.Sandbox.checkout(SoftBank.TestRepo)
  # end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(SoftBank.TestRepo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(SoftBank.TestRepo, {:shared, self()})
    end
  end
end
