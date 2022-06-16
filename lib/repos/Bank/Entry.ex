defmodule SoftBank.Entry do
  @moduledoc """
  Entries are the recording of account debits and credits and can be considered
  as consituting a traditional accounting Journal.
  """

  @type t :: %__MODULE__{
          description: String.t(),
          date: Ecto.Date.t()
        }

  use Ecto.Schema

  import Ecto.Changeset

  alias SoftBank.Amount
  alias SoftBank.Entry
  SoftBank.Config

  schema "softbank_entries" do
    field(:description, :string)
    field(:date, :utc_datetime_usec)

    has_many(:amounts, SoftBank.Amount, on_delete: :delete_all)

    timestamps()
  end

  @fields ~w(description date)a

  @doc """
  Creates a changeset for `SoftBank.Entry`, validating a required `:description` and `:date`,
  casting an provided "debit" and "credit" `SoftBank.Amount`s, and validating that
  those amounts balance.
  """
  def changeset(model, params \\ %{}, default_currency \\ :USD) do
    model
    |> cast(params, @fields)
    |> validate_required([:description, :date])
    |> cast_assoc(:amounts)
    |> validate_debits_and_credits_balance(default_currency)
  end

  @doc """
  Accepts and returns a changeset, appending an error if "credit" and "debit" amounts
  are not equivalent
  """

  def validate_debits_and_credits_balance(changeset, default_currency \\ :USD) do
    amounts = Ecto.Changeset.get_field(changeset, :amounts)
    types = Enum.group_by(amounts, fn i -> i.type end)

    credits = Enum.group_by(types["credit"], fn i -> i.amount.amount end)
    debits = Enum.group_by(types["debit"], fn i -> i.amount.amount end)

    default_amount = Money.new!(default_currency, 0)

    credit_sum =
      Enum.reduce(credits, default_amount, fn {_, i}, acc ->
        amt = List.first(i)
        {_, amt} = Money.add(amt.amount, acc)
        amt
      end)

    debit_sum =
      Enum.reduce(debits, default_amount, fn {_, i}, acc ->
        amt = List.first(i)
        {_, amt} = Money.add(amt.amount, acc)
        amt
      end)

    if credit_sum == debit_sum do
      changeset
    else
      add_error(changeset, :amounts, "Credit and Debit amounts must be equal")
    end
  end

  @doc """
  Accepts an `SoftBank.Entry` and `Ecto.Repo` and returns true/false based on whether
  the associated amounts for that entry sum to zero.
  """
  @spec(balanced?(Ecto.Repo.t(), SoftBank.Entry.t()) :: Boolean.t(), String.t())
  def balanced?(repo \\ Config.repo(), entry = %Entry{}, default_currency \\ :USD) do
    credits =
      Amount
      |> Amount.for_entry(entry)
      |> Amount.select_type("credit")
      |> repo.all

    debits =
      Amount
      |> Amount.for_entry(entry)
      |> Amount.select_type("debit")
      |> repo.all

    default_amount = Money.new(default_currency, 0)

    {_, credit_sum} =
      Enum.reduce(credits, default_amount, fn i, acc ->
        Money.add(i.amount.amount, acc)
      end)

    {_, debit_sum} =
      Enum.reduce(debits, default_amount, fn i, acc ->
        Money.add(i.amount.amount, acc)
      end)

    if credit_sum - debit_sum == 0 do
      true
    else
      false
    end
  end
end
