defmodule Monc.Ledger.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "monc_transactions" do
    field :description, :string

    has_many :postings, Monc.Ledger.Posting

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:description])
    |> cast_assoc(:postings, required: true)
  end
end
