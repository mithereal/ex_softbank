defmodule SoftBank.Config do
  @doc """
  Return value by key from config.exs file.
  """

  alias SoftBank.InvalidConfigError

  def get(name, default \\ nil) do
    Application.get_env(:soft_bank, name, default)
  end

  def repo, do: List.first(Application.fetch_env!(:soft_bank, :ecto_repos))
  def repos, do: Application.fetch_env!(:soft_bank, :ecto_repos)

  @spec config() :: Keyword.t() | none()
  def config() do
    case Application.get_env(:soft_bank, :ecto_repos, :not_found) do
      :not_found ->
        raise InvalidConfigError, "soft_bank config not found"

      config ->
        if not Keyword.keyword?(config) do
          raise InvalidConfigError,
                "soft_bank config was found, but doesn't contain a keyword list."
        end

        config
    end
  end

  def key_type() do
    case Application.get_env(:soft_bank, repo())[:primary_key_type] do
      nil -> :id
      _ -> :binary_id
    end
  end

  def key_type(:migration) do
    case Application.get_env(:soft_bank, repo())[:primary_key_type] do
      nil -> :id
      _ -> :uuid
    end
  end
end
