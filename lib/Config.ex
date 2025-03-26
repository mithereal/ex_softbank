defmodule SoftBank.Config do
  @doc """
  Return value by key from config.exs file.
  """

  defstruct get_dynamic_repo: nil,
            prefix: nil,
            log: false,
            name: SoftBank,
            repo: nil

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

  def new(opts \\ []) do
	  repo = SoftBank.Config.get(:repo)
    struct!(__MODULE__, [repo: repo] ++ opts)
  end
end
