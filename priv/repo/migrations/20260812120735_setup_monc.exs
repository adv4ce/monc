defmodule Monc.Repo.Migrations.SetupMonc do
  use Ecto.Migration

  def up do
    create table(:monc_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :currency, :string, null: false
      add :allow_negative, :bool, default: false, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create table(:monc_transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :description, :string

      timestamps(type: :utc_datetime_usec)
    end

    create table(:monc_postings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :amount, :integer, null: false

      add :transaction_id, references(:monc_transactions, type: :binary_id, on_delete: :delete_all), null: false
      add :account_id, references(:monc_accounts, type: :binary_id, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:monc_postings, [:transaction_id])
    create index(:monc_postings, [:account_id])
  end

  def down do
    drop table(:monc_postings)
    drop table(:monc_transactions)
    drop table(:monc_accounts)
  end
end
