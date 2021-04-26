defmodule SoftBank.Account do
  import Kernel, except: [abs: 1]

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias SoftBank.Repo
  alias SoftBank.Amount
  alias SoftBank.Account
  alias SoftBank.Entry

  @moduledoc """
  An Account represents the individual account.
  """

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

  def to_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @params)
  end

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

  defp with_amounts(query) do
    from(q in query, preload: [:amounts])
  end

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

  def account_balance(repo \\ Config.repo(), account_or_account_list, dates \\ nil) do
    balance(repo, account_or_account_list, dates)
  end

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
        id: a.id
      })
      |> repo.all()
  end

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
