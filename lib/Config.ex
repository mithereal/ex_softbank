defmodule SoftBank.Config do
  @doc """
  Return value by key from config.exs file.
  """
  def get(name, default \\ nil) do
    Application.get_env(:SoftBank, name, default)
  end
end
