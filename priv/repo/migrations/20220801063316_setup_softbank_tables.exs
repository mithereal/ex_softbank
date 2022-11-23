defmodule SoftBank.Repo.Migrations.SetupTables do
  use Ecto.Migration


    def change do
	    execute("CREATE TYPE public.money_with_currency AS (currency_code char(3), amount numeric);")
	    execute("CREATE TYPE public.currency AS (currency_code char(3));")

      create table(:softbank_accounts) do
        add :name, :string, null: false
        add :type, :string, null: false
        add :account_number, :string, null: false
        add :hash, :string, null: false
        add :default_currency, :string, null: false
        add :contra, :boolean, default: false

         timestamps([type: :utc_datetime_usec])
      end

      create index(:softbank_accounts, [:name, :type])

      create table(:softbank_entries) do
        add :description, :string, null: false
        add :date, :utc_datetime_usec, null: false

        timestamps([type: :utc_datetime_usec])
      end

      create index(:softbank_entries, [:date])

      create table(:softbank_amounts) do
         add :type, :string, null: false
        add :amount, :money_with_currency
        add :account_id, references(:softbank_accounts, on_delete: :delete_all), null: false
        add :entry_id, references(:softbank_entries, on_delete: :delete_all), null: false

         timestamps([type: :utc_datetime_usec])
      end

      create index(:softbank_amounts, [:account_id, :entry_id])

        create table(:softbank_currencies) do
        add :name, :string, null: false
        add :digits, :integer, default: 0
        add :symbol, :string, null: false
        add :alt_code, :string, null: false
        add :cash_digits, :integer, default: 0
        add :cash_rounding, :string, null: true
        add :code, :string, null: false
        add :from, :string, null: true
        add :to, :string, null: true
        add :iso_digits, :integer, default: 0
        add :narrow_symbol, :string, null: true
        add :rounding, :integer, default: 0
        add :tender, :boolean, default: false

      end


        create index(:softbank_currencies, [:symbol])

    end
  end