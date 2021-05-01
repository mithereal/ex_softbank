defmodule SoftBank.ExchangeRates.CoinMarketCap do
  @moduledoc """
  Implements the `Money.ExchangeRates` for CoinMarketCap
  Rates service.

  ## Required configuration:

  The configuration key `:coin_market_cap_key` should be
  set to your `app_id`.  for example:

      config :soft_bank,
        coin_market_cap_key: "your_key"

  or configure it via environment variable:

      config :soft_bank,
        coin_market_cap_key: {:system, "coin_market_cap_key"}

  It is also possible to configure an alternative base url for this
  service in case it changes in the future. For example:

      config :soft_bank,
        coin_market_cap_key: "your_key"
        coin_market_cap_url: "https://pro-api.coinmarketcap.com"

  """
  require Logger
  alias SoftBank.ExchangeRates.CoinMarketCap.Retriever

  alias SoftBank.Config

  @behaviour Money.ExchangeRates

  @rate_url "https://pro-api.coinmarketcap.com/v1"

  @doc """
  Update the retriever configuration to include the requirements
  for  CoinMarketCap Rates.  This function is invoked when the
  exchange rate service starts up, just after the ets table
  :exchange_rates is created.

  * `default_config` is the configuration returned by `Money.ExchangeRates.default_config/0`

  Returns the configuration either unchanged or updated with
  additional configuration specific to this exchange
  rates retrieval module.
  """

  def init(default_config) do
    url = Application.get_env(:ex_money, :rate_url, @rate_url)
    api_key = Application.get_env(:ex_money, :exchange_rates_api_key, nil)
    Map.put(default_config, :retriever_options, %{url: url, api_key: api_key})
  end

  def decode_rates(body) do
    %{"data" => data} = Money.json_library().decode!(body)

    add_currencies_to_bank(data)

    rates = marshall_rates(data)

    r =
      rates
      |> Cldr.Map.atomize_keys()
      |> Enum.map(fn
        {k, v} when is_float(v) -> {k, Decimal.from_float(v)}
        {k, v} when is_integer(v) -> {k, Decimal.new(v)}
      end)
      |> Enum.into(%{})
  end

  defp marshall_rates(data) do
    Enum.map(data, fn x ->
      key = "X" <> String.slice(x["symbol"], 0..1)
      value = x["quote"]["USD"]["price"]

      {key, value}
    end)
  end

  defp add_currencies_to_bank(data) do
    Enum.each(data, fn x ->
      key = "X" <> String.slice(x["symbol"], 0..1)

      currency = %{
        name: x["name"],
        digits: 16,
        symbol: key,
        alt_code: x["slug"],
        code: x["symbol"]
      }

      SoftBank.Currencies.new(currency)
    end)
  end

  @doc """
  Retrieves the latest exchange rates from CoinMarketCap site.

  * `config` is the retrieval configuration. When invoked from the
  exchange rates services this will be the config returned from
  `Money.ExchangeRates.config/0`

  Returns:

  * `{:ok, rates}` if the rates can be retrieved

  * `{:error, reason}` if rates cannot be retrieved

  Typically this function is called by the exchange rates retrieval
  service although it can be called outside that context as
  required.

  """
  @spec get_latest_rates(Money.ExchangeRates.Config.t()) :: {:ok, map()} | {:error, String.t()}
  def get_latest_rates(config) do
    url = config.retriever_options.url
    api_key = config.retriever_options.api_key
    retrieve_latest_rates(url, api_key, config)
  end

  defp retrieve_latest_rates(_url, nil, _config) do
    {:error, api_key_not_configured()}
  end

  @latest_rates "/cryptocurrency/listings/latest"
  defp retrieve_latest_rates(url, api_key, config) do
    endpoint = url <> @latest_rates <> "?CMC_PRO_API_KEY=" <> api_key

    Retriever.retrieve_rates(endpoint, config)
  end

  @doc """
  Retrieves the historic exchange rates from CoinMarketCap.

  * `date` is a date returned by `Date.new/3` or any struct with the
    elements `:year`, `:month` and `:day`.

  * `config` is the retrieval configuration. When invoked from the
    exchange rates services this will be the config returned from
    `Money.ExchangeRates.config/0`

  Returns:

  * `{:ok, rates}` if the rates can be retrieved

  * `{:error, reason}` if rates cannot be retrieved

  Typically this function is called by the exchange rates retrieval
  service although it can be called outside that context as
  required.
  """
  def get_historic_rates(date, config) do
    url = config.retriever_options.url
    api_key = config.retriever_options.api_key
    retrieve_historic_rates(date, url, api_key, config)
  end

  defp retrieve_historic_rates(_date, _url, nil, _config) do
    {:error, api_key_not_configured()}
  end

  @historic_rates "/historical/"
  defp retrieve_historic_rates(%Date{calendar: Calendar.ISO} = date, url, api_key, config) do
    date_string = Date.to_string(date)

    Retriever.retrieve_rates(
      url <> @historic_rates <> "?CMC_PRO_API_KEY=" <> api_key,
      config
    )
  end

  defp retrieve_historic_rates(%{year: year, month: month, day: day}, url, api_key, config) do
    case Date.new(year, month, day) do
      {:ok, date} -> retrieve_historic_rates(date, url, api_key, config)
      error -> error
    end
  end

  defp api_key_not_configured do
    "exchange_rates_api_key is not configured.  Rates are not retrieved."
  end
end
