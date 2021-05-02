defmodule SoftBank.Transfer do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  alias SoftBank.Amount
  alias SoftBank.Account
  alias SoftBank.Transfer
  alias SoftBank.Entry
  alias SoftBank.Repo
  alias SoftBank.Config

  @moduledoc """
  Transfer from one account to another.
  """

  embedded_schema do
    field(:amount, Money.Ecto.Composite.Type)
    field(:message, :integer)
    field(:description, :string)

    embeds_one(:sender, Account)
    embeds_one(:recipient, Account)
  end

  def changeset(from_account, struct, to_account \\ %{}, params \\ %{}) do
    struct
    |> cast(params, [:message, :description, :amount])
    |> put_embed(:sender, from_account)
    |> put_destination_customer(to_account)
  end

  defp put_destination_customer(%{valid?: false} = changeset, _), do: changeset

  defp put_destination_customer(changeset, to) do
    account_number = to.account_number

    applied_changeset = apply_changes(changeset)

    if account_number == applied_changeset.sender.account_number do
      add_error(changeset, :recipient, "cannot transfer to the same account")
    else
      case Repo.one(from(a in Account, where: a.account_number == ^account_number)) do
        %Account{} = account ->
          put_embed(changeset, :recipient, account)

        nil ->
          add_error(changeset, :recipient, "is invalid")
      end
    end
  end

  def send(from_account_struct, to_account_struct, params) do
    changeset = changeset(from_account_struct, %Transfer{}, to_account_struct, params)

    if changeset.valid? do
      transfer = apply_changes(changeset)

      source_account = transfer.sender
      destination_account = transfer.recipient
      amount = transfer.amount

      {_, account_balance} = Account.balance(Config.repo(), source_account, nil)

      sum_amt = Money.sub!(account_balance, amount)
      zero_amt = Money.new(:USD, 0)

      case Money.compare(sum_amt, zero_amt) == :gt do
        true ->
          entry_changeset = %Entry{
            description:
              "Transfer : " <>
                to_string(amount.amount) <>
                " from " <>
                source_account.account_number <> " to " <> destination_account.account_number,
            date: DateTime.utc_now(),
            amounts: [
              %Amount{
                amount: amount,
                type: "credit",
                account_id: destination_account.id
              },
              %Amount{
                amount: amount,
                type: "debit",
                account_id: source_account.id
              }
            ]
          }

          Repo.insert(entry_changeset)

          {:ok, transfer}

        false ->
          changeset = add_error(changeset, :message, "insufficient funds")
          {:error, changeset}
      end
    else
      {:error, changeset}
    end
  end
end
