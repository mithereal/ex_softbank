defmodule SoftBank.Owner do
  use SoftBank.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias SoftBank.Owner
  alias SoftBank.Repo
  alias SoftBank.Account
  alias SoftBank.Config

  @typedoc "An Owner type."
  @type t :: %__MODULE__{
          name: String.t(),
          account_number: String.t()
        }

  schema "softbank_owners" do
    field(:name, :string)
    field(:account_number, :string)

    has_many(:accounts, Account)
  end

  @params ~w(account_number name )a

  @required_fields ~w(account_number)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @params)
    |> validate_required(@required_fields)
  end

  @doc false
  def to_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @params)
  end

  @doc """
  Create new account with default ledgers
  """
  def new(name) do
    config = SoftBank.Config.new()

    default_currency = Config.get(:default_currency, :USD)

    account_number = Account.bank_account_number()

    params =
      %Owner{name: name, account_number: account_number}

    owner =
      Repo.insert!(config, params)
      |> Map.delete(:accounts)

    accounts = Account.new(owner, default_currency)
    %{owner: owner, accounts: accounts}
  end

  @doc """
  Fetch the Account from the Repo.
  """

  def fetch(account, repo \\ Repo)

  def fetch(%{account_number: account_number}, repo) do
    config = SoftBank.Config.new()

    query =
      Owner
      |> where([a], a.account_number == ^account_number)
      |> select([a], %Owner{
        account_number: a.account_number,
        name: a.name,
        id: a.id
      })

    result =
      config
      |> repo.one(query)

    config
    |> repo.preload(result, :accounts)
  end
end
