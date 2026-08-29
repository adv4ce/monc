defmodule Monc.Accounts do
  @moduledoc """
  Module for managing bank accounts
  """
  alias Monc.Repo.Proxy
  alias Monc.Accounts.Account
  alias Monc.Ledger.Posting
  import Ecto.Query

  @doc """
  Create new account
  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Proxy.insert()
  end

  @doc """
  Get account by UUID
  """
  def get_account(id) do
    Proxy.get(Account, id)
  end

  @doc """
  Update account by UUID
  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Proxy.update()
  end

  @doc """
  Get `allow_negative` status for many accounts
  """
  def get_overdraft_and_currency_settings(account_ids) do
    query =
      from a in Account,
      where: a.id in ^account_ids,
      select: %{account_id: a.id, currency: a.currency, allow_negative: a.allow_negative},
      order_by: a.id,
      lock: "FOR UPDATE"

    Proxy.all(query)
  end

  @doc """
  Get SUM of all transactions for many accounts
  """
  def sum_transactions_by_account_ids(account_ids) do
    query =
      from p in Posting,
      where: p.account_id in ^account_ids,
      select: %{account_id: p.account_id, amount_sum: coalesce(sum(p.amount), 0)},
      group_by: p.account_id

    Proxy.all(query)
  end
end
