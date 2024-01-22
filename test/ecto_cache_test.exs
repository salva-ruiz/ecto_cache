defmodule EctoCacheTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = EctoCache.start_link([])
    {:ok, pid: pid}
  end

  test "EctoCache.start_link/1 starts a process", %{pid: pid} do
    assert is_pid(pid)
    assert Process.alive?(pid)
  end

  test "EctoCache.start_link/1 starts a process with a registered name" do
    pid = Process.whereis(EctoCache)
    assert is_pid(pid)
    assert Process.alive?(pid)
  end

  test "EctoCache.cache/3 stores a value in to cache" do
    assert EctoCache.cache(:hello, fn -> :world end) == :world
  end

  test "EctoCache.cache/3 stores a value in the cache for some seconds" do
    assert EctoCache.cache(:hello, fn -> :world end, 5) == :world
  end

  test "EctoCache.delete/1 deletes a cached value" do
    assert EctoCache.delete(:hello) == :ok
  end

  test "EctoCache.delete/2 deletes a cached value and returns the result of the first argument" do
    assert EctoCache.delete({:ok, 42}, :hello) == {:ok, 42}
    assert EctoCache.delete({:error, 42}, :hello) == {:error, 42}
  end
end
