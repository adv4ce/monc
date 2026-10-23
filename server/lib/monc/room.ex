defmodule Monc.Room do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(_) do
    ets_ref = :ets.new(:room_users, [:set, :public, :read_concurrency])
    
    {:ok, %{users_table: ets_ref}}
  end

  @impl true
  def handle_cast({:join, pid, name}, users) do
    {:noreply, new_users}
  end

  @impl true
  def handle_cast({:leave, pid, name}, users) do
    {:noreply, new_users}
  end
end
