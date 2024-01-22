defmodule EctoCache do
  @moduledoc """
  Implements an in-memory process to cache the results of database queries.
  """

  use GenServer

  @doc false
  @opaque t :: %__MODULE__{value: term(), updated_at: Time.t()}
  defstruct [:value, :updated_at]

  ## Client implementation

  @doc """
  Starts the `EctoCache` process.

  You should not use this function directly. Instead add `EctoCache` to your
  supervision tree as explained in the module documentation.
  """
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc """
  Gets the value of `key` from the cache, if available. If the value has not
  been cached yet or it has expired, executes the `fun` function and cache
  their result.

  You can set `lifetime` to the number of seconds you want the value to be
  available or to `infinity` so that it never expires. Every time the `key`
  value is read, the availability time is reset again to `lifetime`.

  ## Example

      iex> EctoCache.cache(:posts, &Repo.all(Post), 600)
      [%Post{}, ...]

  """
  @spec cache(atom(), (-> term()), {non_neg_integer() | :infinity}) :: term()
  def cache(key, fun, lifetime \\ :infinity)
      when is_atom(key) and is_function(fun) and
             (lifetime == :infinity or (is_integer(lifetime) and lifetime >= 0)) do
    case GenServer.call(__MODULE__, {:get, key, lifetime}) do
      {:ok, value} ->
        value

      :error ->
        value = fun.()
        GenServer.cast(__MODULE__, {:put, key, value})
        value
    end
  end

  @doc """
  Deletes the cached `key` value.

  Use this function when the cached values have changed and you want to disable
  the cache to avoid reading outdated data.

  This function always returns `:ok` regardless of whether or not a cached value
  exists for the `key`.

  ## Examples

      iex> EctoCache.delete(:posts)
      :ok

  """
  @spec delete(atom()) :: :ok
  def delete(key) when is_atom(key), do: GenServer.call(__MODULE__, {:delete, key})

  @doc """
  Same as `EctoCache.delete/1` but designed to be used in a pipeline as a
  result of a `Ecto.Repo` write operation.

  This function integrates with `Ecto.Repo.insert/2`, `Ecto.Repo.update/2` and
  `Ecto.Repo.delete/2`, deleting the cache _only_ if the operation was carried
  out and returning the result of the database operation.

  ## Examples

      iex> Repo.insert(post) |> EctoCache.delete(:posts)
      {:ok, %Post{}}

      iex> Repo.update(post) |> EctoCache.delete(:posts)
      {:ok, %Post{}}

      iex> Repo.delete(post) |> EctoCache.delete(:posts)
      {:ok, %Post{}}

  """
  @spec delete({:ok, Ecto.Schema.t()}, atom()) :: {:ok, Ecto.Schema.t()}
  def delete({:ok, schema}, key) when is_atom(key) do
    GenServer.call(__MODULE__, {:delete, key})
    {:ok, schema}
  end

  @spec delete({:error, Ecto.Changeset.t()}, atom()) :: {:error, Ecto.Changeset.t()}
  def delete({:error, changeset}, _key), do: {:error, changeset}

  ## GenServer implementation

  @impl true
  def init(_opts), do: {:ok, %{}}

  @impl true
  def handle_cast({:put, key, value}, state) do
    cached = struct(__MODULE__, value: value, updated_at: Time.utc_now())
    {:noreply, Map.put(state, key, cached)}
  end

  @impl true
  def handle_call({:get, key, :infinity}, _from, state) do
    case Map.fetch(state, key) do
      {:ok, cached} -> {:reply, {:ok, cached.value}, state}
      :error -> {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:get, key, lifetime}, _from, state) do
    with {:ok, cached} <- Map.fetch(state, key),
         now <- Time.utc_now(),
         true <- Time.diff(now, cached.updated_at) < lifetime do
      cached = struct(cached, updated_at: now)
      {:reply, {:ok, cached.value}, Map.put(state, key, cached)}
    else
      _cached_expired_or_key_not_found ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    {:reply, :ok, Map.delete(state, key)}
  end
end
