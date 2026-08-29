defmodule AccountTests do
  use ExUnit.Case, async: true

  alias Monc.Accounts
  alias Monc.Accounts.Account

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Monc.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end

  describe "create_account/1" do
    test "create_account with valid attrs" do
      valid_attrs = %{currency: "USD", allow_negative: false}

      assert {:ok, %Account{} = account} = Accounts.create_account(valid_attrs)

      assert account.currency == "USD"
      refute account.allow_negative
    end

    test "create_account with invalid attrs" do
      invalid_attrs = %{allow_negative: false}

      assert {:error, %Ecto.Changeset{}} = Accounts.create_account(invalid_attrs)
    end
  end

  describe "update_account/2" do
    setup do
      {:ok, account} = Accounts.create_account(%{currency: "EUR"})

      %{account: account}
    end

    test "update account allow_negative flag", %{account: account} do
      update_attrs = %{allow_negative: true}

      assert {:ok, %Account{} = updated} = Accounts.update_account(account, update_attrs)
      assert updated.allow_negative == true

      assert updated.currency == account.currency
    end
  end
end
