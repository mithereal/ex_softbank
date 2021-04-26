defmodule SoftBank.Cldr do
  use Cldr,
    locales: Application.get_env(:soft_bank, :locales, ["en", "fr", "zh"]),
    default_locale: Application.get_env(:soft_bank, :default_locale, "en"),
    providers: [Cldr.Number, Money]
end
