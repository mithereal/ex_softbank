defmodule SoftBank.TestRepo do
  use Ecto.Repo,
    otp_app: :soft_bank,
    adapter: Ecto.Adapters.Postgres
end
