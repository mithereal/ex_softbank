defmodule SoftBank.Currency.Reload do
  use Task
  require Logger

  @moduledoc false

  def start_link(_data \\ []) do
    Logger.info("Custom Currencies will be retrieved now and then every 300 seconds.")
    Task.start_link(&poll/0)
  end

  defp poll() do
    receive do
    after
      300_000 ->
        SoftBank.Currencies.reload()
        poll()
    end
  end
end
