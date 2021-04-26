defmodule SoftBank.Note do
  import Kernel, except: [abs: 1]
  import Money

  @moduledoc """
    Defines a `SoftBank.Note` struct along with convenience methods for working with currencies.
  """

  defstruct amount: Money.new(:USD, 0), currency: Application.get_env(:note, :default_currency)

  @doc ~S"""
  Create a new `SoftBank.Note` struct using a default currency.
  The default currency can be set in the system Mix config.

  ## Example Config:

      config :note,
        default_currency: :USD

  ## Example:

      SoftBank.Note.new(123)
      %SoftBank.Note{amount: 123, currency: :USD}
  """

  def new(amount) do
    currency = Application.get_env(:note, :default_currency)

    if currency do
      Money.new(currency, amount)
    else
      raise ArgumentError,
            "to use SoftBank.Note.new/1 you must set a default currency in your application config."
    end
  end
end
