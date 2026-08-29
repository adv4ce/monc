defmodule Monc.Ledger.Posting do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "monc_postings" do
    field :amount, :integer

    belongs_to :transaction, Monc.Ledger.Transaction
    belongs_to :account, Monc.Accounts.Account

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:amount, :transaction_id, :account_id])
    |> validate_required([:amount, :account_id])
    |> foreign_key_constraint(:transaction_id)
    |> foreign_key_constraint(:account_id)
  end
end
