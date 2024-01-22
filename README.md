# EctoCache

`EctoCache` is a process that implements an in-memory cache to store the
results of database queries with `Ecto`. It is ideal for small lists of data
that are constantly being read from the database and change very little such as
a list of countries or product categories in an e-commerce.

## Setup

Add `ecto_cache` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_cache, "~> 0.1.0"}
  ]
end
```

Run `mix deps.get` to install the dependencies.

Add `ecto_cache` as a worker to the supervision tree in your `application.ex`
inside the `start/2` function:

```elixir
def start(_type, _args) do
  children = [
    # ...
    EctoCache
  ]

  # ...
end
```
