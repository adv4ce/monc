defmodule Monc.Ledger do
  @moduledoc """
  Module for manipulate transactions
  """
  import Ecto.Query
  alias Ecto.Multi
  alias Monc.Repo.Proxy
  alias Monc.Ledger.{Transaction, Posting}
  alias Monc.Accounts

  @doc """
    Record transaction from attrs
  """
  def record_transaction(attrs) do
    posting_data = Map.get(attrs, :postings, [])
    total_amount = Enum.reduce(posting_data, 0, fn p, acc -> acc + p.amount end)

    accounts_postring = Enum.reduce(posting_data, %{}, fn p, acc ->
      Map.update(acc, p.account_id, p.amount, fn existing_amount ->
        existing_amount + p.amount
      end)
    end)

    if total_amount != 0 or length(posting_data) < 2 do
      {:error, :unbalanced_transaction}
    else
      Multi.new()
      |> Multi.run(:restricted_ids, fn _repo, _changes ->
        get_overdraft_settings_and_check_valid_currencies(accounts_postring)
      end)
      |> Multi.insert(:transaction, Transaction.changeset(%Transaction{}, attrs))
      |> Multi.run(:check_balances, fn _repo, %{restricted_ids: restricted_ids} ->
        check_for_negative_balance(restricted_ids)
      end)
      |> Proxy.transaction()
    end
  end

  def get_balance(account_id) do
    query =
      from p in Posting,
        where: p.account_id == ^account_id,
        select: coalesce(sum(p.amount), 0)

    Proxy.one(query)
  end

  defp get_overdraft_settings_and_check_valid_currencies(accounts_postring) do
    account_settings =
      Map.keys(accounts_postring)
      |> Enum.sort()
      |> Accounts.get_overdraft_and_currency_settings()

    {unique_currencies, restricted_ids} =
      Enum.reduce(account_settings, {MapSet.new(), []}, fn a, {currencies_set, ids_acc} ->
        new_currencies_set = MapSet.put(currencies_set, a.currency)

        new_ids_acc = if !a.allow_negative and Map.fetch!(accounts_postring, a.account_id) < 0, do: [a.account_id | ids_acc], else: ids_acc

        {new_currencies_set, new_ids_acc}
      end)

    if MapSet.size(unique_currencies) != 1 do
      {:error, :mixed_currencies}
    else
      {:ok, restricted_ids}
    end
  end

  defp check_for_negative_balance(restricted_ids) do
    sums = Accounts.sum_transactions_by_account_ids(restricted_ids)

    sums_map = Map.new(sums, fn i -> {i.account_id, i.amount_sum} end)
    if Enum.all?(restricted_ids, fn account_id ->
      Map.fetch!(sums_map, account_id) >= 0
    end) do
      {:ok, :valid}
    else
      {:error, :insufficient_funds}
    end
  end
end
