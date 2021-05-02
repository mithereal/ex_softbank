defmodule SoftBank.Currencies do
  alias SoftBank.Currency
  alias SoftBank.Config

  require Logger

  def init(pid, table) do
    currencies = Config.repo().all(Currency)

    Enum.map(currencies, fn x ->
      Cldr.Currency.new(x.symbol,
        cash_digits: x.cash_digits,
        cash_rounding: x.cash_rounding,
        code: x.code,
        digits: x.digits,
        from: x.from,
        iso_digits: x.iso_digits,
        name: x.name,
        narrow_symbol: x.narrow_symbol,
        rounding: x.rounding,
        symbol: x.symbol,
        tender: x.tender,
        to: x.to
      )
    end)
  end

  def new(params) do
    changeset = SoftBank.Currency.changeset(%SoftBank.Currency{}, params)
    {status, x} = Repo.insert(changeset)

    Logger.info("Loading New Currency: " <> x.name)

    if status == :ok do
      Cldr.Currency.new(x.symbol,
        cash_digits: x.cash_digits,
        cash_rounding: x.cash_rounding,
        code: x.code,
        digits: x.digits,
        from: x.from,
        iso_digits: x.iso_digits,
        name: x.name,
        narrow_symbol: x.narrow_symbol,
        rounding: x.rounding,
        symbol: x.symbol,
        tender: x.tender,
        to: x.to
      )
    end
  end

  def reload() do
    currencies = Config.repo().all(Currency)

    Logger.info("Reloading Custom Currencies")

    Enum.map(currencies, fn x ->
      Cldr.Currency.new(x.symbol,
        cash_digits: x.cash_digits,
        cash_rounding: x.cash_rounding,
        code: x.code,
        digits: x.digits,
        from: x.from,
        iso_digits: x.iso_digits,
        name: x.name,
        narrow_symbol: x.narrow_symbol,
        rounding: x.rounding,
        symbol: x.symbol,
        tender: x.tender,
        to: x.to
      )
    end)
  end
end
