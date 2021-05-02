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
    field(:message, :integer)
    field(:account_number, :string)
    field(:amount, Money.Ecto.Composite.Type)
    field(:description, :string)

    embeds_one(:sender, Account)
    embeds_one(:recipient, Account)
  end

  def changeset(from_account, struct, to_account \\ %{}, params \\ %{}) do
    struct
    |> cast(params, [:message, :description, :account_number])
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

  ## params must be of %Account{} type
  def send(from_account, to_account, amount, params) do
    changeset = changeset(from_account, %Transfer{}, to_account, params)

    if changeset.valid? do
      transfer = apply_changes(changeset)
      source_account = from_account
      destination_account = transfer.recipient

      transfer = %{transfer | amount: amount}

      transfer_request =
        create_request(source_account, destination_account, amount)

        account_balance = Account.balance(Config.repo, source_account, nil)

      case Money.subtract(account_balance, amount)  > 0 do
        true ->
          entry_changeset = %Entry{
            description:
              "Transfer : " <>
                transfer_request.reciever.amount <>
                " from " <>
                transfer_request.reciever.account <> " to " <> transfer_request.reciever.account,
            date: DateTime.utc_now(),
            amounts: [
              %Amount{
                amount: transfer_request.sender.amount,
                type: "credit",
                account_id: transfer_request.reciever.account.id
              },
              %Amount{
                amount: transfer_request.sender.amount,
                type: "debit",
                account_id: transfer_request.sender.account.id
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

  defp create_request(source, destination,  amount) do
    %{
      sender: %{
        account: source.account_number,
        amount: amount
      },
      reciever: %{
        account: destination.account_number,
        amount: amount
      }
    }
  end
end
