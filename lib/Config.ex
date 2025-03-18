defmodule SoftBank.Config do
  @doc """
  Return value by key from config.exs file.
  """

  alias SoftBank.Repo

  def get(name, default \\ nil) do
    Application.get_env(:soft_bank, name, default)
  end

  def key_type() do
    case Application.get_env(:soft_bank, :primary_key_type) do
      nil -> :integer
      :id -> :integer
      :integer -> :integer
      _ -> :binary_id
    end
  end
end
