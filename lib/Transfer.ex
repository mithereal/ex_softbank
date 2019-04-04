defmodule SoftBank.Transfer do

  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

alias SoftBank.Amount
alias SoftBank.Account
alias SoftBank.Transfer
alias SoftBank.Entry
alias SoftBank.Repo

  @moduledoc """
  Transfer from one account to another.
  """
  
  embedded_schema do
    field :message, :integer
    field :amount, SoftBank.Note.Ecto.Type
    field :description, :string

    embeds_one :sender, Account
    embeds_one :recipient, Account
  end


  def changeset(account, struct, params \\ %{}) do
    struct
    |> cast(params, [:message, :description])
    |> validate_required([:description])
    |> put_embed(:sender, account)
    |> put_destination_customer(account)
  end

  defp put_destination_customer(%{valid?: false} = changeset, _), do: changeset
  defp put_destination_customer(changeset, sender) do
    account_number = get_change(changeset, :account_number)

    if account_number == sender.account_number do
      add_error(changeset, :recipient, "cannot transfer to the same account")
    else
      case Repo.one(from a in Account, where: a.account_number == ^account_number) do
        %Account{} = account ->
          put_embed(changeset, :recipient, account)
        nil ->
          add_error(changeset, :recipient, "is invalid")
      end
    end
  end

## params must be of %Account{} type
  def send(account, params) do
    changeset = changeset(account, %Transfer{}, params)

    if changeset.valid? do
      transfer = apply_changes(changeset)
      source_account = account
      destination_account = transfer.recipient

      amount = case source_account.currency == destination_account.currency do
      true -> transfer.amount
      _-> SoftBank.Currency.Conversion.convert(transfer.amount, destination_account.currency)
      end



      transfer = %{transfer | amount: amount}

      transfer_request = create_request(source_account, destination_account, transfer.description, amount)

      case account.balance() - amount > 0 do
        true -> entry_changeset = %Entry{
        description: "Transfer : " <> transfer_request.debit.amount <> " from " <> transfer_request.debit.account <> " to " <> transfer_request.debit.account,
        date: Ecto.Date.utc(),
         amounts: [
                  %Amount{ amount: transfer_request.sender.amount, type: "credit", account_id: transfer_request.reciever.account.id },
                  %Amount{ amount: transfer_request.sender.amount, type: "debit", account_id: transfer_request.sender.account.id }]
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

  defp create_request(source, destination, description, amount) do
    %{
      sender: %{account: source.account_number, description: source.description, amount: source.amount},
      reciever: %{account: destination.account_number, description: destination.description, amount: destination.amount}
    }

  end

end
