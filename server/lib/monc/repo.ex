defmodule Monc.Repo do
  use Ecto.Repo,
    otp_app: :monc,
    adapter: Ecto.Adapters.Postgres
end
