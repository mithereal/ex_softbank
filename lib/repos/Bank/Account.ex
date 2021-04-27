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

     `account = %Fuentes.Account{name: "Drawing", type: "asset", contra: true}`

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

  alias SoftBank.Repo
  alias SoftBank.Amount
  alias SoftBank.Account
  alias SoftBank.Entry

  @typedoc "An Account type."
  @type t :: %__MODULE__{
          name: String.t(),
          account_number: String.t(),
          type: String.t(),
          contra: Boolean.t(),
          hash: String.t(),
          amounts: [SoftBank.Amount]
        }

  schema "softbank_accounts" do
    field(:name, :string)
    field(:account_number, :string)
    field(:hash, :string)
    field(:type, :string)
    field(:contra, :boolean)

    field(:balance, Money.Ecto.Composite.Type, virtual: true)

    has_many(:amounts, Amount, on_delete: :delete_all)
    has_many(:entry, through: [:amounts, :entry], on_delete: :delete_all)

    timestamps
  end

  @params ~w(account_number type contra  name hash id)a
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

  @doc false
  def to_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @params)
  end

  @doc """
  Create new account with default ledgers
  """
  def new(name \\ nil) do
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
      |> validate_required(@required_fields)
      |> Repo.insert()

    liablilty_struct = %{name: name <> "Liabilities", type: "liability"}

    account_number = bank_account_number()

    {_, credit_account} =
      %Account{}
      |> Account.to_changeset(liablilty_struct)
      |> put_change(:account_number, account_number)
      |> put_change(:hash, hash)
      |> validate_required(@required_fields)
      |> Repo.insert()

    equity_struct = %{name: name <> "Equity", type: "equity"}

    account_number = bank_account_number()

    {_, equity_account} =
      %Account{}
      |> Account.to_changeset(equity_struct)
      |> put_change(:account_number, account_number)
      |> put_change(:hash, hash)
      |> validate_required(@required_fields)
      |> Repo.insert()

    %{
      hash: hash,
      debit_account: debit_account,
      credit_account: credit_account,
      equity_account: equity_account
    }
  end

  @doc false
  defp with_amounts(query) do
    from(q in query, preload: [:amounts])
  end

  @doc false
  @spec amount_sum(Ecto.Repo.t(), SoftBank.Account.t(), String.t(), map) :: Decimal.t()
  def amount_sum(repo \\ Repo, account, type, dates \\ []) do
    dc = Enum.count(dates)

    records =
      case dc == 0 do
        true ->
          Amount
          |> Amount.for_account(account)
          |> Amount.select_type(type)
          |> repo.all()

        false ->
          Amount
          |> Amount.for_account(account)
          |> Amount.dated(dates)
          |> Amount.select_type(type)
          |> repo.all()
      end

    reply =
      if Enum.count(records) > 0 do
        default_currency = account.default_currency

        default_records =
          Enum.map(records, fn x ->
            Money.to_currency(x.amount, default_currency, Money.ExchangeRates.latest_rates())
          end)

        Money.add(default_records)
      else
        Money.new(0)
      end

    IO.inspect(reply, label: "reply in repo.bank.acount.amount_sum ")
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
          account_number: account_number,
          type: type,
          contra: contra
        },
        dates
      )
      when is_nil(dates) do
    credits = Account.amount_sum(repo, account, "credit")
    debits = Account.amount_sum(repo, account, "debit")

    if type in @credit_types && !contra do
      balance = Money.sub(debits, credits)
    else
      balance = Money.sub(credits, debits)
    end
  end

  @doc false
  def balance(
        repo,
        account = %Account{
          account_number: account_number,
          type: type,
          contra: contra
        },
        dates
      ) do
    credits = Account.amount_sum(repo, account, "credit", dates)
    debits = Account.amount_sum(repo, account, "debit", dates)

    if type in @credit_types && !contra do
      balance = Money.sub(debits, credits)
    else
      balance = Money.sub(credits, debits)
    end
  end

  @doc falses
  def balance(repo, accounts, dates) when is_list(accounts) do
    balance =
      Enum.reduce(accounts, Decimal.new(0.0), fn account, acc ->
        Decimal.add(Account.balance(repo, account, dates), acc)
      end)

    IO.inspect(balance, label: "balance in repo.bank.acount.balance ")
    balance
  end

  defp hash_id(number \\ 20) do
    Nanoid.generate(number, "0123456789")
  end

  defp bank_account_number(number \\ 12) do
    base_acct_number = Nanoid.generate(number, "0123456789")
  end

  @doc """
  Fetch the Account from the Repo.
  """
  def fetch(%{account_number: account_number}, repo \\ Repo) do
    query =
      Account
      |> where([a], a.account_number == ^account_number)
      |> select([a], %{
        account_number: a.account_number,
        type: a.type,
        contra: a.contra,
        id: a.id
      })
      |> repo.all()
  end

  @doc """
  Computes the starting balance for all accounts in the provided Ecto.Repo.
  Returns Decimal type.
  """
  def starting_balance(repo \\ Config.repo_from_config()) do
    accounts = repo.all(Account)
    accounts_by_type = Enum.group_by(accounts, fn i -> String.to_atom(i.type) end)

    accounts_by_type =
      Enum.map(accounts_by_type, fn {account_type, accounts} ->
        {account_type, Account.balance(repo, accounts)}
      end)

    IO.inspect(accounts_by_type, label: "accounts_by_type in repo.bank.acount.starting_balance ")

    accounts_by_type[:asset]
    |> Money.sub(accounts_by_type[:liability])
    |> Money.sub(accounts_by_type[:equity])
  end
end
