defmodule SoftBank.Repo.Migrations.Tables do
    use Ecto.Migration
 
    def change do
      create table(:softbank_accounts) do
        add :name, :string, null: false
        add :type, :string, null: false
        add :account_number, :string, null: false
        add :hash, :string, null: false
        add :currency, :string, null: false
        add :contra, :boolean, default: false
  
        timestamps
      end

      create index(:softbank_accounts, [:name, :type])
  
      create table(:softbank_entries) do
        add :description, :string, null: false
        add :date, :date, null: false
  
        timestamps
      end

      create index(:softbank_entries, [:date])
  
      create table(:softbank_amounts) do
        add :amount, :decimal, precision: 20, scale: 10, null: false
        add :account_id, references(:softbank_accounts, on_delete: :delete_all), null: false
        add :entry_id, references(:entries, on_delete: :delete_all), null: false
  
        timestamps
      end
      
      create index(:softbank_amounts, [:account_id, :entry_id])
  
  
    end
  end