defmodule SoftBank.Currency.Conversion.Source do
  @moduledoc """
  Behaviour for all currency rate sources.

  """

  @callback load() :: {:ok, SoftBank.Currency.Conversion.Rates.t()} | {:error, binary}
end
