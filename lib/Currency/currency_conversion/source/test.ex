defmodule SoftBank.Currency.Conversion.Source.Test do
  @moduledoc """
  Currency Conversion Source for Tests
  """

  @behaviour SoftBank.Currency.Conversion.Source

  @default_rates %SoftBank.Currency.Conversion.Rates{
    base: :EUR,
    rates: %{
      AUD: 1.4205,
      BGN: 1.9558,
      BRL: 3.4093,
      CAD: 1.4048,
      CHF: 1.0693,
      CNY: 7.3634,
      CZK: 27.021,
      DKK: 7.4367,
      GBP: 0.85143,
      HKD: 8.3006,
      HRK: 7.48,
      HUF: 310.98,
      IDR: 14_316.0,
      ILS: 4.0527,
      INR: 72.957,
      JPY: 122.4,
      KRW: 1248.1,
      MXN: 22.476,
      MYR: 4.739,
      NOK: 8.9215,
      NZD: 1.4793,
      PHP: 53.373,
      PLN: 4.3435,
      RON: 4.4943,
      RUB: 64.727,
      SEK: 9.466,
      SGD: 1.5228,
      THB: 37.776,
      TRY: 4.1361,
      USD: 1.07,
      ZAR: 14.31
    }
  }

  @doc """
  Load current currency rates from config.

  ### Examples

      iex> SoftBank.Currency.Conversion.Source.Test.load
      {:ok, %SoftBank.Currency.Conversion.Rates{base: :EUR,
        rates: %{AUD: 1.4205, BGN: 1.9558, BRL: 3.4093, CAD: 1.4048, CHF: 1.0693,
         CNY: 7.3634, CZK: 27.021, DKK: 7.4367, GBP: 0.85143, HKD: 8.3006,
         HRK: 7.48, HUF: 310.98, IDR: 14316.0, ILS: 4.0527, INR: 72.957,
         JPY: 122.4, KRW: 1248.1, MXN: 22.476, MYR: 4.739, NOK: 8.9215,
         NZD: 1.4793, PHP: 53.373, PLN: 4.3435, RON: 4.4943, RUB: 64.727,
         SEK: 9.466, SGD: 1.5228, THB: 37.776, TRY: 4.1361, USD: 1.07,
         ZAR: 14.31}}}

  """
  def load do
    rates = Application.get_env(:soft_bank, :test_rates, @default_rates)
    {:ok, cast(rates)}
  end

  defp cast({base, rates}), do: %SoftBank.Currency.Conversion.Rates{base: base, rates: rates}
  defp cast(rates = %SoftBank.Currency.Conversion.Rates{}), do: rates

  def default_rates, do: @default_rates
end
