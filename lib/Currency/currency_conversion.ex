defmodule SoftBank.Currency.Conversion do
  @moduledoc """
  Module to Convert Currencies.
  """

  alias SoftBank.Currency.Conversion.Rates
  alias SoftBank.Currency.Conversion.UpdateWorker

  @doc """
  Convert from currency A to B.

  ### Example

      iex> SoftBank.Currency.Conversion.convert(SoftBank.Note.new(7_00, :CHF), :USD, %SoftBank.Currency.Conversion.Rates{base: :EUR,
      ...>  rates: %{CHF: 0.5, USD: 0.75}})
      %SoftBank.Note{amount: 10_50, currency: :USD}

      iex> SoftBank.Currency.Conversion.convert(SoftBank.Note.new(7_00, :EUR), :USD, %SoftBank.Currency.Conversion.Rates{base: :EUR,
      ...>  rates: %{CHF: 0.5, USD: 0.75}})
      %SoftBank.Note{amount: 5_25, currency: :USD}

      iex> SoftBank.Currency.Conversion.convert(SoftBank.Note.new(7_00, :CHF), :EUR, %SoftBank.Currency.Conversion.Rates{base: :EUR,
      ...>  rates: %{CHF: 0.5, USD: 0.75}})
      %SoftBank.Note{amount: 14_00, currency: :EUR}

      iex> SoftBank.Currency.Conversion.convert(SoftBank.Note.new(0, :CHF), :EUR, %SoftBank.Currency.Conversion.Rates{base: :EUR,
      ...>  rates: %{CHF: 0.5, USD: 0.75}})
      %SoftBank.Note{amount: 0, currency: :EUR}

      iex> SoftBank.Currency.Conversion.convert(SoftBank.Note.new(7_20, :CHF), :CHF, %SoftBank.Currency.Conversion.Rates{base: :EUR,
      ...>  rates: %{CHF: 0.5, USD: 0.75}})
      %SoftBank.Note{amount: 7_20, currency: :CHF}

  """
  @spec convert(SoftBank.Note.t, atom, Rates.t) :: SoftBank.Note.t
  def convert(amount, to_currency, rates \\ UpdateWorker.get_rates())
  def convert(%SoftBank.Note{amount: 0}, to_currency, _), do: SoftBank.Note.new(0, to_currency)
  def convert(amount = %SoftBank.Note{currency: currency}, currency, _), do: amount
  def convert(%SoftBank.Note{amount: amount, currency: currency}, to_currency, %Rates{base: currency, rates: rates}) do
    SoftBank.Note.new(round(amount * Map.fetch!(rates, to_currency)), to_currency)
  end
  def convert(%SoftBank.Note{amount: amount, currency: currency}, to_currency, %Rates{base: to_currency, rates: rates}) do
    SoftBank.Note.new(round(amount / Map.fetch!(rates, currency)), to_currency)
  end
  def convert(amount, to_currency, rates) do
    convert(convert(amount, rates.base, rates), to_currency, rates)
  end

  @doc """
  Get all currencies

  ### Examples

      iex> SoftBank.Currency.Conversion.get_currencies(%SoftBank.Currency.Conversion.Rates{base: :EUR,
      ...>  rates: %{CHF: 0.5, USD: 0.75}})
      [:EUR, :CHF, :USD]

  """
  @spec get_currencies(Rates.t) :: [atom]
  def get_currencies(rates \\ UpdateWorker.get_rates())
  def get_currencies(%Rates{base: base, rates: rates}), do: [base | Map.keys(rates)]
end
