defmodule LedgerTest do
  use ExUnit.Case, async: true

  alias Monc.Accounts
  alias Monc.Accounts.Account
  alias Monc.Ledger

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Monc.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    assert {:ok, %Account{} = system_account} = Accounts.create_account(%{currency: "USD", allow_negative: true})
    assert {:ok, %Account{} = alice_account} = Accounts.create_account(%{currency: "USD", allow_negative: false})
    assert {:ok, %Account{} = bob_account} = Accounts.create_account(%{currency: "USD", allow_negative: false})
    {:ok,
    system_account: system_account,
    alice_account: alice_account,
    bob_account: bob_account}
  end
  
  describe "get_balance/1" do
    test "get new account balance", %{
      alice_account: alice_account
    } do
      assert 0 == Ledger.get_balance(alice_account.id)
    end

    test "balance after a sequence of operations", %{
      system_account: system_account,
      alice_account: alice_account
    } do
      tx = %{
        postings: [
          %{account_id: system_account.id, amount: -500},
          %{account_id: alice_account.id, amount: 500},
          %{account_id: alice_account.id, amount: -150},
          %{account_id: system_account.id, amount: 150},
          %{account_id: alice_account.id, amount: -50},
          %{account_id: system_account.id, amount: 50}
        ]
      }

      assert {:ok, _tx} = Ledger.record_transaction(tx)

      assert 300 == Ledger.get_balance(alice_account.id)
    end

    test "negative system balance", %{
      system_account: system_account,
      alice_account: alice_account
    } do
      tx = %{
        postings: [
          %{account_id: system_account.id, amount: -1000},
          %{account_id: alice_account.id, amount: 1000},
        ]
      }

      assert {:ok, _tx} = Ledger.record_transaction(tx)

      assert -1000 == Ledger.get_balance(system_account.id)
    end
  end

  describe "record_transaction/1" do
    test "default valid transaction", %{
      system_account: system_account,
      alice_account: alice_account,
      bob_account: bob_account
    } do
      tx = %{
        postings: [
          %{account_id: system_account.id, amount: -1000},
          %{account_id: alice_account.id, amount: 1000},
        ]
      }

      assert {:ok, _tx} = Ledger.record_transaction(tx)

      tx = %{
        postings: [
          %{account_id: alice_account.id, amount: -300},
          %{account_id: bob_account.id, amount: 300}
        ]
      }

      assert {:ok, _tx} = Ledger.record_transaction(tx)

      assert 700 == Ledger.get_balance(alice_account.id)
      assert 300 == Ledger.get_balance(bob_account.id)
    end

    test "split transaction", %{
      system_account: system_account,
      alice_account: alice_account,
      bob_account: bob_account
    } do
      assert {:ok, %Account{} = charlie_account} = Accounts.create_account(%{currency: "USD", allow_negative: false})

      tx = %{
        postings: [
          %{account_id: system_account.id, amount: -1000},
          %{account_id: alice_account.id, amount: 1000},
        ]
      }
      assert {:ok, _tx} = Ledger.record_transaction(tx)

      tx = %{
        postings: [
          %{account_id: alice_account.id, amount: -1000},
          %{account_id: bob_account.id, amount: 700},
          %{account_id: charlie_account.id, amount: 300}
        ]
      }

      assert {:ok, _tx} = Ledger.record_transaction(tx)

      assert 0 == Ledger.get_balance(alice_account.id)
      assert 700 == Ledger.get_balance(bob_account.id)
      assert 300 == Ledger.get_balance(charlie_account.id)
    end

    test "mixed currencies", %{
      system_account: system_account,
      alice_account: alice_account,
    } do
      assert {:ok, %Account{} = alex_account} = Accounts.create_account(%{currency: "RUB", allow_negative: false})

      tx = %{
        postings: [
          %{account_id: system_account.id, amount: -500},
          %{account_id: alice_account.id, amount: 500},
        ]
      }
      assert {:ok, _tx} = Ledger.record_transaction(tx)

      tx = %{
        postings: [
          %{account_id: alice_account.id, amount: -500},
          %{account_id: alex_account.id, amount: 500},
        ]
      }

      assert {:error, _a, :mixed_currencies, _tx} = Ledger.record_transaction(tx)
    end
  end
end
