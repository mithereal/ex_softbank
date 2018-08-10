if Code.ensure_compiled?(Ecto.Type) do
  defmodule Bank.Note.Ecto.Type do
    @moduledoc """
    Provides a type for Ecto usage.
    The underlying data type should be an integer.

    This type expects you to use a single currency.
    The currency must be defined in your configuration.

        config :money,
          default_currency: :GBP

    ## Migration Example

        create table(:my_table) do
          add :amount, :integer
        end

    ## Schema Example

        schema "my_table" do
          field :amount, Bank.Note.Ecto.Type
        end
    """

    @behaviour Ecto.Type

    @spec type :: :integer
    def type, do: :integer

    @spec cast(String.t | integer) :: {:ok, Bank.Note.t}
    def cast(val)
    def cast(str) when is_binary(str) do
      Bank.Note.parse(str)
    end
    def cast(int) when is_integer(int), do: {:ok, Bank.Note.new(int)}
    def cast(%Bank.Note{}=money), do: {:ok, money}
    def cast(_), do: :error

    @spec load(integer) :: {:ok, Bank.Note.t}
    def load(int) when is_integer(int), do: {:ok, Bank.Note.new(int)}

    @spec dump(integer | Bank.Note.t) :: {:ok, :integer}
    def dump(int) when is_integer(int), do: {:ok, int}
    def dump(%Bank.Note{} = m), do: {:ok, m.amount}
    def dump(_), do: :error
  end
end
