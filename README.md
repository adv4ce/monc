**English** | [Русский](README.ru.md)

# Monc 💰

A double-entry ledger engine built on Elixir, Ecto and PostgreSQL.

Money is never created or destroyed: a transaction is a set of postings that sums to zero. Balances are not stored anywhere, they are computed as the sum of an account's postings.

## 📐 Model

| Table | What it is |
|---|---|
| `monc_accounts` | An account: currency and the `allow_negative` flag |
| `monc_transactions` | An atomic group of postings |
| `monc_postings` | A change to one account's balance by one transaction |

Postings are only ever appended, nothing is updated or deleted.

## ✅ Guarantees

A transaction is recorded only if all four conditions hold:

- its postings sum to zero
- all accounts share the same currency
- an account with `allow_negative: false` does not go below zero
- either every posting is written, or none

## 🔒 Concurrency

Write order:

1. `SELECT ... FOR UPDATE` on every account in the transaction, `ORDER BY id`
2. insert the transaction and its postings
3. recompute balances and reject if anyone went negative

The lock is taken **before** the insert. Otherwise inserting a posting makes Postgres take a weak `FOR KEY SHARE` on the account by itself, two parallel transactions both acquire it happily, and then both hang forever trying to upgrade it to `FOR UPDATE`. `ORDER BY id` covers the second, ordinary kind of deadlock: transactions walking overlapping accounts in different orders.

The balance check runs after the insert and inside the same transaction, so it sees its own postings and reads the final balance directly.

## 🚀 Usage

```elixir
{:ok, treasury} = Monc.Accounts.create_account(%{currency: "USD", allow_negative: true})
{:ok, alice}    = Monc.Accounts.create_account(%{currency: "USD"})

{:ok, _} =
  Monc.Ledger.record_transaction(%{
    description: "top up",
    postings: [
      %{account_id: treasury.id, amount: -1000},
      %{account_id: alice.id, amount: 1000}
    ]
  })

Monc.Ledger.get_balance(alice.id)
#=> 1000
```

Amounts are integers in minor units (cents), never floats.

Errors:

```elixir
{:error, :unbalanced_transaction}
{:error, :restricted_ids, :mixed_currencies, _}
{:error, :check_balances, :insufficient_funds, _}
```

## 🧪 Running

Requires Elixir 1.19+ and Postgres. Copy `.env.example` to `.env` and fill it in.

```bash
mix deps.get
mix ecto.create
mix ecto.migrate
mix test
```

`test/concurrency_test.exs` is the load test: a thousand accounts, a hundred thousand random transfers between them in parallel, asserting that no account went below zero.

```
%{ok: 98572, errors: 0, insufficient_funds: 1428}
Finished in 33.6 seconds
```

The rejections are legitimate insufficient funds. `errors: 0` means no worker crashed, which is how a deadlock would show up.

## ⚠️ Not there yet

- **Idempotency.** A client retrying after a dropped connection will record the transfer twice. Needs an `idempotency_key` with a unique index.
- **Verified embedding.** `Repo.Proxy` is meant to let a host supply its own repo, but that path has never been exercised. Two things block it: `Monc.Application` starts its own `Repo` unconditionally, and the migrations are not exposed to a host.
- **A delivery layer.** This is a library, there is no HTTP or UI on top of it.
- **Cheap balances.** `SUM` over an account's whole history gets more expensive as it grows, eventually this needs snapshots.
