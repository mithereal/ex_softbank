defmodule SoftBank.Account do
  import Kernel, except: [abs: 1]

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias SoftBank.Repo
  alias SoftBank.Amount
  alias SoftBank.Account
  alias SoftBank.Entry

  @moduledoc false

  schema "softbank_accounts" do
    field(:name, :string)
    field(:account_number, :string)
    field(:hash, :string)
    field(:type, :string)
    field(:contra, :boolean)
    field(:currency, :string)
    field(:balance, Money.Ecto.Composite.Type, virtual: true)

    has_many(:amounts, Amount, on_delete: :delete_all)
    has_many(:entry, through: [:amounts, :entry], on_delete: :delete_all)

    timestamps
  end

  @params ~w(account_number type contra currency name hash)a
  @required_fields ~w(account_number)a

  @credit_types ["asset"]
  @debit_types ["liability", "equity"]

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @params)
    |> validate_required(@required_fields)
  end

  def to_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @params)
  end

  def new(currency \\ "USD", name \\ nil) do
    hash = hash_id()

    name =
      case name do
        nil -> ""
        _ -> name <> " "
      end

    asset_struct = %{name: name <> "Assets", type: "asset"}

    account_number = bank_account_number()

    {_, debit_account} =
      %Account{}
      |> Account.to_changeset(asset_struct)
      |> put_change(:account_number, account_number)
      |> put_change(:hash, hash)
      |> put_change(:currency, currency)
      |> validate_required(@required_fields)
      |> Repo.insert()

    liablilty_struct = %{name: name <> "Liabilities", type: "liability"}

    account_number = bank_account_number()

    {_, credit_account} =
      %Account{}
      |> Account.to_changeset(liablilty_struct)
      |> put_change(:account_number, account_number)
      |> put_change(:hash, hash)
      |> put_change(:currency, currency)
      |> validate_required(@required_fields)
      |> Repo.insert()

    equity_struct = %{name: name <> "Equity", type: "equity"}

    account_number = bank_account_number()

    {_, equity_account} =
      %Account{}
      |> Account.to_changeset(equity_struct)
      |> put_change(:account_number, account_number)
      |> put_change(:hash, hash)
      |> put_change(:currency, currency)
      |> validate_required(@required_fields)
      |> Repo.insert()

    %{
      hash: hash,
      debit_account: debit_account,
      credit_account: credit_account,
      equity_account: equity_account
    }
  end

  defp with_amounts(query) do
    from(q in query, preload: [:amounts])
  end




  def amount_sum(account, type, dates \\ nil, repo \\ Repo) do
    [sum] = case dates do
      nil ->  Amount
      |> Amount.for_account(account)
      |> Amount.sum_type(type)
      |> repo.all()
      _->  Amount
      |> Amount.for_account(account)
      |> Amount.dated(dates)
      |> Amount.sum_type(type)
      |> Repo.all()
    end


    if sum do
      sum
    else
      Decimal.new(0)
    end
  end

    def balance(account_or_account_list, dates \\ nil)do
      balance(account_or_account_list, dates)
  end

  def balance(account = %Account{account_number: account_number, type: type, contra: contra, currency: currency}, dates) when is_nil(dates) do
    credits = Account.amount_sum(account, "credit")
    debits = Account.amount_sum(account, "debit")

    if type in @credit_types && !contra do
      balance = Decimal.sub(debits, credits)
    else
      balance = Decimal.sub(credits, debits)
    end
  end

  def balance(account = %Account{account_number: account_number, type: type, contra: contra, currency: currency}, dates) do
    credits = Account.amount_sum(account, "credit", dates)
    debits = Account.amount_sum(account, "debit", dates)

    if type in @credit_types && !contra do
      balance = Decimal.sub(debits, credits)
    else
      balance = Decimal.sub(credits, debits)
    end
  end

  def balance(accounts, dates) when is_list(accounts) do
    Enum.reduce(accounts, Decimal.new(0.0), fn account, acc ->
      Decimal.add(Account.balance(account, dates), acc)
    end)
  end


  defp hash_id(number \\ 20) do
    Base.encode64(:crypto.strong_rand_bytes(number))
  end

  defp bank_account_number(number \\ 12) do
    Nanoid.generate(number, "0123456789")
  end


  def fetch(%{account_number: account_number}, repo \\ Repo) do
    query =
      Account
      |> where([a], a.account_number == ^account_number)
      |> select([a], %{
        account_number: a.account_number,
        type: a.type,
        contra: a.contra,
        currency: a.currency
      })
      |> Repo.all()
  end
end
