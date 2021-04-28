defmodule SoftBank.Config do
  @doc """
  Return value by key from config.exs file.
  """
  def get(name, default \\ nil) do
    Application.get_env(:soft_bank, name, default)
  end

  def repo, do: List.first(Application.fetch_env!(:soft_bank, :ecto_repos))
end
