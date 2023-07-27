defmodule SoftBank.Owner do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias SoftBank.Owner
  alias SoftBank.Repo
  alias SoftBank.Amount
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
    default_currency = Config.get(:default_currency, :USD)

    account_number = Account.bank_account_number()

    {_, owner} =
      %Owner{name: name, account_number: account_number}
      |> Repo.insert()

    Account.new(owner, default_currency)
  end
end