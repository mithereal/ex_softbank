defmodule SoftBank.Repo.Migrations.Tables do
  use Ecto.Migration

  def change do
    key_type = SoftBank.Config.key_type(:migration)

    case key_type do
      :uuid ->
        create table(:softbank_owners, primary_key: false) do
          add(:id, key_type, primary_key: true)
          add(:name, :string, null: false)
          add(:account_number, :string, null: false)
        end

        create(index(:softbank_owners, [:name, :account_number]))

        create table(:softbank_accounts, primary_key: false) do
          add(:id, key_type, primary_key: true)
          add(:name, :string, null: false)
          add(:type, :string, null: false)
          add(:account_number, :string, null: false)
          add(:default_currency, :string, null: false)
          add(:contra, :boolean, default: false)

          add(:owner_id, references(:softbank_owners, on_delete: :delete_all), null: false)

          timestamps(type: :utc_datetime_usec)
        end

        create(index(:softbank_accounts, [:name, :type]))

        create table(:softbank_entries, primary_key: false) do
          add(:id, key_type, primary_key: true)
          add(:description, :string, null: false)
          add(:date, :utc_datetime_usec, null: false)

          timestamps(type: :utc_datetime_usec)
        end

        create(index(:softbank_entries, [:date]))

        create table(:softbank_amounts, primary_key: false) do
          add(:id, key_type, primary_key: true)
          add(:type, :string, null: false)
          add(:amount, :money_with_currency)
          add(:account_id, references(:softbank_accounts, on_delete: :delete_all), null: false)
          add(:entry_id, references(:softbank_entries, on_delete: :delete_all), null: false)

          timestamps(type: :utc_datetime_usec)
        end

        create(index(:softbank_amounts, [:account_id, :entry_id]))

        create table(:softbank_currencies, primary_key: false) do
          add(:id, key_type, primary_key: true)
          add(:name, :string, null: false)
          add(:digits, :integer, default: 0)
          add(:symbol, :string, null: false)
          add(:alt_code, :string, null: false)
          add(:cash_digits, :integer, default: 0)
          add(:cash_rounding, :string, null: true)
          add(:code, :string, null: false)
          add(:from, :string, null: true)
          add(:to, :string, null: true)
          add(:iso_digits, :integer, default: 0)
          add(:narrow_symbol, :string, null: true)
          add(:rounding, :integer, default: 0)
          add(:tender, :boolean, default: false)
        end

        create(index(:softbank_currencies, [:symbol]))

      _ ->
        create table(:softbank_owners) do
          add(:name, :string, null: false)
          add(:account_number, :string, null: false)
        end

        create(index(:softbank_owners, [:name, :account_number]))

        create table(:softbank_accounts) do
          add(:name, :string, null: false)
          add(:type, :string, null: false)
          add(:account_number, :string, null: false)
          add(:default_currency, :string, null: false)
          add(:contra, :boolean, default: false)

          add(:owner_id, references(:softbank_owners, on_delete: :delete_all), null: false)

          timestamps(type: :utc_datetime_usec)
        end

        create(index(:softbank_accounts, [:name, :type]))

        create table(:softbank_entries) do
          add(:description, :string, null: false)
          add(:date, :utc_datetime_usec, null: false)

          timestamps(type: :utc_datetime_usec)
        end

        create(index(:softbank_entries, [:date]))

        create table(:softbank_amounts) do
          add(:type, :string, null: false)
          add(:amount, :money_with_currency)
          add(:account_id, references(:softbank_accounts, on_delete: :delete_all), null: false)
          add(:entry_id, references(:softbank_entries, on_delete: :delete_all), null: false)

          timestamps(type: :utc_datetime_usec)
        end

        create(index(:softbank_amounts, [:account_id, :entry_id]))

        create table(:softbank_currencies) do
          add(:name, :string, null: false)
          add(:digits, :integer, default: 0)
          add(:symbol, :string, null: false)
          add(:alt_code, :string, null: false)
          add(:cash_digits, :integer, default: 0)
          add(:cash_rounding, :string, null: true)
          add(:code, :string, null: false)
          add(:from, :string, null: true)
          add(:to, :string, null: true)
          add(:iso_digits, :integer, default: 0)
          add(:narrow_symbol, :string, null: true)
          add(:rounding, :integer, default: 0)
          add(:tender, :boolean, default: false)
        end

        create(index(:softbank_currencies, [:symbol]))
    end
  end
end
