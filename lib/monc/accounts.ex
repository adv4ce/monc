defmodule Monc.Accounts do
  @moduledoc """
  Module for managing bank accounts
  """
  alias Monc.Repo.Proxy
  alias Monc.Accounts.Account

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
end
