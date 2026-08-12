defmodule Monc.Repo.Proxy do
  @moduledoc """
  Динамический прокси для вызова Repo приложения-потребителя
  """

  defp repo, do: Application.get_env(:monc, :repo, Monc.Repo)

  def insert(x), do: repo().insert(x)
  def insert!(x), do: repo().insert!(x)
  def update(x), do: repo().update(x)
  def get(q, id), do: repo().get(q, id)
  def all(q), do: repo().all(q)
  def one(q), do: repo().one(q)
  def transaction(f, opts \\ []), do: repo().transaction(f, opts)
end
