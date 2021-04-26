defmodule SoftBank.Currency do
  use Ecto.Schema

  import Ecto.Changeset

  alias SoftBank.Repo
  alias SoftBank.Currency

  @moduledoc false

  schema "softbank_currencies" do
    field(:name, :string)
    field(:digits, :integer)
    field(:symbol, :string)
    field(:alt_code, :string)
    field(:cash_digits, :integer)
    field(:cash_rounding, :integer)
    field(:code, :string)
    field(:from, :string)
    field(:iso_digits, :string)
    field(:narrow_symbol, :string)
    field(:rounding, :integer)
    field(:tender, :boolean)
    field(:to, :string)
  end

  @params ~w(name digits symbol alt_code cash_digits cash_rounding code from iso_digits narrow_symbol rounding tender to)a
  @required_fields ~w(name digits symbol)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @params)
    |> validate_required(@required_fields)
  end
end
