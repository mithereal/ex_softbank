defmodule SoftBank.Amount do
  @moduledoc """
  An Amount represents the individual debit or credit for a given account and is
  part of a balanced entry.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, only: [from: 1, from: 2]

  alias SoftBank.Entry
  alias SoftBank.Account

  schema "softbank_amounts" do
    field(:amount, Money.Ecto.Composite.Type)
    field(:type, :string)

    belongs_to(:entry, Entry)
    belongs_to(:account, Account)

    timestamps
  end

  @params ~w(amount type)a
  @required_fields ~w()a

  @amount_types ["credit", "debit"]

  @doc """
  Creates an amount changeset associated with a `SoftBank.Entry` and `SoftBank.Account`.
  A type ("credit" or "debit"), as well as, an amount greater than 0 must be specified.
  """

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @params)
    |> Ecto.Changeset.assoc_constraint([:entry, :account])
    |> validate_required([:amount, :type])
    |> validate_amount_type()
    |> validate_inclusion(:type, @amount_types)
  end

  def validate_amount_type(model) do
    type = model.amount.type
    IO.inspect(type, label: "type in repo.bank.amount.validate_amount_type")
    valid = Enum.member?(Money.Currency.known_current_currencies(), type)

    case valid do
      true -> model
      false -> add_error(model, :type, "invalid", additional: "invalid currency type")
    end
  end

  @doc false
  def for_entry(query, entry) do
    from(c in query,
      join: p in assoc(c, :entry),
      where: p.id == ^entry.id
    )
  end

  @doc false
  def for_account(query, account) do
    from(c in query,
      join: p in assoc(c, :account),
      where: p.id == ^account.id
    )
  end

  @doc false
  def sum_type(query, type) do
    from(c in query,
      where: c.type == ^type,
      select: sum(c.amount)
    )
  end

  def select_type(query, type) do
    from(c in query,
      join: p in assoc(c, :account),
      where: p.type == ^type,
      select: c.amount
    )
  end

  @doc false
  def dated(query, %{from_date: from_date, to_date: to_date}) do
    from(c in query,
      join: p in assoc(c, :entry),
      where: p.date >= ^from_date,
      where: p.date <= ^to_date
    )
  end

  @doc false
  def dated(query, %{from_date: from_date}) do
    from(c in query,
      join: p in assoc(c, :entry),
      where: p.date >= ^from_date
    )
  end

  @doc false
  def dated(query, %{to_date: to_date}) do
    from(c in query,
      join: p in assoc(c, :entry),
      where: p.date <= ^to_date
    )
  end

  def note(amount) do
    currency = Application.get_env(:soft_bank, :default_currency)

    if currency do
      new(amount, currency)
    else
      raise ArgumentError,
            "to use Amount.new/1 you must set a default currency in your application config."
    end
  end

  def new(int, currency) do
  end
end
