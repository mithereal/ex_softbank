defmodule SoftBank.Cldr do
  use Cldr,
    locales: Application.compile_env(:soft_bank, :locales, ["en", "fr", "zh"]),
    default_locale: Application.compile_env(:soft_bank, :default_locale, "en"),
    providers: [Cldr.Number, Money]
end
