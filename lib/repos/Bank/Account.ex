defmodule SoftBank.Account do
  @moduledoc """
  An Account represents accounts in the system which are of _asset_,
  _liability_, or _equity_ types, in accordance with the "accounting equation".

  Each account must be set to one of the following types:

     | TYPE      | NORMAL BALANCE | DESCRIPTION                            |
     | :-------- | :-------------:| :--------------------------------------|
     | asset     | Debit          | Resources owned by the Business Entity |
     | liability | Credit         | Debts owed to outsiders                |
     | equity    | Credit         | Owners rights to the Assets            |

   Each account can also be marked as a _Contra Account_. A contra account will have it's
   normal balance swapped. For example, to remove equity, a "Drawing" account may be created
   as a contra equity account as follows:

     `account = %SoftBank.Account{name: "Drawing", type: "asset", contra: true}`

   At all times the balance of all accounts should conform to the "accounting equation"

     *Assets = Liabilities + Owner's Equity*

   Each account type acts as it's own ledger.

  For more details see:

  [Wikipedia - Accounting Equation](http://en.wikipedia.org/wiki/Accounting_equation)
  [Wikipedia - Debits, Credits, and Contra Accounts](http://en.wikipedia.org/wiki/Debits_and_credits)
  """

  import Kernel, except: [abs: 1]

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias SoftBank.Owner
  alias SoftBank.Repo
  alias SoftBank.Amount
  alias SoftBank.Account
  alias SoftBank.Config

  @typedoc "An Account type."
  @type t :: %__MODULE__{
          name: String.t(),
          account_number: String.t(),
          type: String.t(),
          contra: Boolean.t(),
          default_currency: String.t(),
          amounts: [SoftBank.Amount]
        }

  schema "softbank_accounts" do
    field(:name, :string)
    field(:account_number, :string)
    field(:type, :string)
    field(:contra, :boolean)
    field(:default_currency, :string)

    belongs_to(:owner, Owner)

    field(:balance, Money.Ecto.Composite.Type, virtual: true)

    has_many(:amounts, Amount, on_delete: :delete_all)
    has_many(:entry, through: [:amounts, :entry], on_delete: :delete_all)

    timestamps()
  end

  @params ~w(account_number type contra name id default_currency)a

  @credit_types ["asset"]
  @required_fields ~w(account_number)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @params)
    |> cast_assoc(params, "owner")
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
  def new(owner) do
    default_currency = Config.get(:default_currency, :USD)

    new(owner, default_currency)
  end

  def new(owner, currency) do
    name = owner.name

    currency =
      case currency do
        :default -> Config.get(:default_currency, :USD)
        _ -> currency
      end

    known? = Cldr.Currency.known_currency_code?(currency)

    case known? do
      true ->
        currency = to_string(currency)

        asset_struct = %{name: name <> " Assets", type: "asset", default_currency: currency}

        account_number = bank_account_number()

        {_, debit_account} =
          %Account{}
          |> Account.to_changeset(asset_struct)
          |> put_change(:account_number, account_number)
          |> put_assoc(:owner, owner)
          |> validate_required(@required_fields)
          |> Repo.insert()

        liablilty_struct = %{
          name: name <> " Liabilities",
          type: "liability",
          default_currency: currency
        }

        account_number = bank_account_number()

        {_, credit_account} =
          %Account{}
          |> Account.to_changeset(liablilty_struct)
          |> put_change(:account_number, account_number)
          |> put_assoc(:owner, owner)
          |> validate_required(@required_fields)
          |> Repo.insert()

        equity_struct = %{name: name <> " Equity", type: "equity", default_currency: currency}

        account_number = bank_account_number()

        {_, equity_account} =
          %Account{}
          |> Account.to_changeset(equity_struct)
          |> put_change(:account_number, account_number)
          |> put_assoc(:owner, owner)
          |> validate_required(@required_fields)
          |> Repo.insert()

        %{
          debit_account: debit_account,
          credit_account: credit_account,
          equity_account: equity_account
        }

      false ->
        {:error, "unknown currency"}
    end
  end

  @doc false
  @spec amount_sum(Ecto.Repo.t(), SoftBank.Account.t(), String.t()) :: Decimal.t()
  def amount_sum(repo, account, type) do
    records =
      Amount
      |> Amount.for_account(account)
      |> Amount.select_type(type)
      |> repo.all()

    default_currency = account.default_currency

    default_currency = String.to_atom(default_currency)

    latest_rates = Money.ExchangeRates.latest_rates()

    rates =
      case(latest_rates) do
        {:error, _rates} -> []
        {:ok, rates} -> rates
      end

    default_records =
      Enum.map(records, fn x ->
        Money.to_currency!(x, default_currency, rates)
      end)

    new_amt = Money.new(default_currency, 0)

    reply =
      Enum.reduce(default_records, new_amt, fn r, acc ->
        {_, new_amt} = Money.add(r, acc)
        new_amt
      end)

    reply
  end

  @doc false
  @spec amount_sum(Ecto.Repo.t(), SoftBank.Account.t(), String.t(), map) :: Decimal.t()
  def amount_sum(repo, account, type, dates) do
    records =
      Amount
      |> Amount.for_account(account)
      |> Amount.dated(dates)
      |> Amount.select_type(type)
      |> repo.all()

    default_currency = account.default_currency

    default_currency = String.to_atom(default_currency)

    latest_rates = Money.ExchangeRates.latest_rates()

    rates =
      case(latest_rates) do
        {:error, _rates} -> []
        {:ok, rates} -> rates
      end

    default_records =
      Enum.map(records, fn x ->
        Money.to_currency!(x, default_currency, rates)
      end)

    new_amt = Money.new(default_currency, 0)

    reply =
      Enum.reduce(default_records, new_amt, fn r, acc ->
        {_, new_amt} = Money.add(r, acc)
        new_amt
      end)

    reply
  end

  @doc """
  Computes the account balance for a given `SoftBank.Account` in a given
  Ecto.Repo when provided with a map of dates in the format
  `%{from_date: from_date, to_date: to_date}`.
  Returns Decimal type.
  """

  @spec balance(Ecto.Repo.t(), [SoftBank.Account.t()], Ecto.Date.t()) :: Decimal.t()
  def account_balance(repo \\ Config.repo(), account_or_account_list, dates \\ nil) do
    balance(repo, account_or_account_list, dates)
  end

  @doc """
  Computes the account balance for a list of `SoftBank.Account` in a given
  Ecto.Repo inclusive of all entries. This function is intended to be used with a
  list of `SoftBank.Account`s of the same type.
  Returns Decimal type.
  """
  # Balance for individual account with dates
  def balance(
        repo,
        account = %Account{
          account_number: _account_number,
          type: type,
          contra: contra,
          default_currency: _default_currency
        },
        dates
      )
      when is_nil(dates) do
    credits = Account.amount_sum(repo, account, "credit")
    debits = Account.amount_sum(repo, account, "debit")

    credits =
      case is_nil(credits) do
        true ->
          data = Money.new(:USD, 0)
          [data]

        false ->
          credits
      end

    debits =
      case is_nil(debits) do
        true ->
          data = Money.new(:USD, 0)
          [data]

        false ->
          debits
      end

    if type in @credit_types && !contra do
      Money.sub(debits, credits)
    else
      Money.sub(credits, debits)
    end
  end

  @doc false
  def balance(
        repo,
        account = %Account{
          account_number: _account_number,
          type: type,
          contra: contra,
          default_currency: _default_currency
        },
        dates
      ) do
    credits = Account.amount_sum(repo, account, "credit", dates)
    debits = Account.amount_sum(repo, account, "debit", dates)

    credits =
      case is_nil(credits) do
        true ->
          data = Money.new(:USD, 0)
          [data]

        false ->
          credits
      end

    debits =
      case is_nil(debits) do
        true ->
          data = Money.new(:USD, 0)
          [data]

        false ->
          debits
      end

    if type in @credit_types && !contra do
      Money.sub(debits, credits)
    else
      Money.sub(credits, debits)
    end
  end

  @doc false
  def balance(repo, accounts, dates) when is_list(accounts) do
    new_amt = Money.new(:USD, 0)

    balance =
      Enum.reduce(accounts, new_amt, fn account, acc ->
        {_, money} = Account.balance(repo, account, dates)

        {_, new_amt} = Money.add(money, acc)
        new_amt
      end)

    balance
  end

  def bank_account_number(number \\ 12) do
    Nanoid.generate(number, "0123456789")
  end

  @doc """
  Fetch the Account from the Repo.
  """

  def fetch(account, repo \\ Repo)

  def fetch(%{account_number: account_number}, repo) do
    Account
    |> where([a], a.account_number == ^account_number)
    |> select([a], %Account{
      account_number: a.account_number,
      type: a.type,
      contra: a.contra,
      id: a.id,
      default_currency: a.default_currency
    })
    |> repo.one()
  end

  @doc """
  Computes a test balance for all accounts in the provided Ecto.Repo.
  Returns Money type.
  """
  def test_balance(repo \\ Config.repo()) do
    accounts = repo.all(Account)

    default_currency = Config.get(:default_currency, :USD)

    case Enum.count(accounts) > 0 do
      true ->
        accounts_by_type = Enum.group_by(accounts, fn i -> String.to_atom(i.type) end)

        accounts_by_type =
          Enum.map(accounts_by_type, fn {account_type, accounts} ->
            {account_type, Account.account_balance(repo, accounts)}
          end)

        accounts_by_type[:asset]
        |> Money.sub!(accounts_by_type[:liability])
        |> Money.sub!(accounts_by_type[:equity])

      false ->
        Money.new(default_currency, 0)
    end
  end
end
