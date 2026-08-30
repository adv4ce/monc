defmodule ConcurrencyTest do
  use ExUnit.Case, async: false

  alias Monc.Accounts
  alias Monc.Ledger

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.mode(Monc.Repo, :auto)

    on_exit(fn ->
      Monc.Repo.delete_all(Monc.Ledger.Posting)
      Monc.Repo.delete_all(Monc.Ledger.Transaction)
      Monc.Repo.delete_all(Monc.Accounts.Account)

      Ecto.Adapters.SQL.Sandbox.mode(Monc.Repo, :manual)
    end)

    # len/info
    test_mode = "len"

    # count of test accounts
    accounts_count = 1000

    # initial balance every new test account
    balance_amount = 10_000

    # transactions count
    transactions_count = 10_000

    {:ok, system_account} = Accounts.create_account(%{currency: "USD", allow_negative: true})
    {:ok, %{
      system_account: system_account,
      test_mode: test_mode,
      accounts_count: accounts_count,
      balance_amount: balance_amount,
      transactions_count: transactions_count
    }}
  end

  @tag timeout: :infinity
  test "emulation of multiple transactions", %{system_account: system_account, test_mode: test_mode, accounts_count: accounts_count, balance_amount: balance_amount, transactions_count: transactions_count} do
    accounts = Enum.map(1..accounts_count, fn _i ->
      {:ok, account} = Accounts.create_account(%{currency: "USD", allow_negative: false})
      account
    end)

    user_ids = Enum.map(accounts, & &1.id)

    Enum.map(accounts, fn a ->
      tx = %{
        postings: [
          %{account_id: system_account.id, amount: -balance_amount},
          %{account_id: a.id, amount: balance_amount},
        ]
      }
      assert {:ok, _tx} = Ledger.record_transaction(tx)
    end)

    result =
      Enum.map(1..transactions_count, fn _tx ->
        [sender, receiver] = Enum.take_random(accounts, 2)
        amount = Enum.random(1..10_000)
        %{
            postings: [
              %{account_id: sender.id, amount: -amount},
              %{account_id: receiver.id, amount: amount}
            ]
          }
      end)
      |> Task.async_stream(fn tx -> Ledger.record_transaction(tx) end, max_concurrency: 80, queue_target: 1000, queue_interval: 5000, timeout: :infinity, ordered: false)
      |> Enum.to_list()
      |> Enum.reduce(%{ok: [], insufficient_funds: [], errors: []}, fn tx, acc ->
        case tx do
          {:ok, {:error, :check_balances, :insufficient_funds, _}} ->
            %{acc | insufficient_funds: acc.insufficient_funds ++ [tx]}
          {:ok, _tx} ->
            %{acc | ok: acc.ok ++ [tx]}
          _error ->
            %{acc | errors: acc.error ++ [tx]}
        end
      end)

    case test_mode do
      "len" ->
        result
        |> Map.new(fn {k, v} -> {k, length(v)} end)
        |> IO.inspect(label: "Результаты теста (len)")

      "info" ->
        result
        |> IO.inspect(label: "Результаты теста (len)")
    end

    balances = Accounts.sum_transactions_by_account_ids(user_ids)

    min_balance =
    balances
    |> Enum.map(fn b -> b.amount_sum end)
    |> Enum.min()

    assert min_balance >= 0
  end
end
