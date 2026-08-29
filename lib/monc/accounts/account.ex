defmodule Monc.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "monc_accounts" do
    field :currency, :string
    field :allow_negative, :boolean, default: false

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:currency, :allow_negative])
    |> validate_required([:currency])
    |> validate_length(:currency, min: 3, max: 5)
  end
end
