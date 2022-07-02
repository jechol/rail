# ReatherLite

`Reather` is a shortcut of `Reader` + `Either` monads pattern.

It makes you define and unwrap the `Reather` easiliy by using `reather` macro.

## Installation

```elixir
def deps do
  [
    {:reather_lite, "~> 0.1.0"}
  ]
end
```

## Usage

### Basic usage

`reather` macro defines a function returns `Reather`.

```elixir
defmodule Target do
  use Reather

  reather foo(a, b) do
    a + b
  end
end

iex> Target.foo(1, 1)
%Reather{...}
```

The `Reather` is lazily evaluated, so it do nothing until call `Reather.run/1`.

```elixir
iex> Target.foo(1, 1) |> Reather.run()
{:ok, 2}
```

The result of `Reather` is always `{:ok, value}` or `{:error, error}`.

In `reather` block, the `ok` tuple will be automatically unwrapped with `<-` operator.

```elixir
defmodule Target do
  use Reather

  reather foo() do
    a <- {:ok, 1}         # a = 1
    {b, c} <- {:ok, 2, 3} # b = 2, c = 3
    d = nil
    ^d <- :ok

    a + b + c
  end
end

iex> Target.foo() |> Reather.run()
{:ok, 6}
```

Also, a `Reather` unwrap into a value with `<-` operator.

```elixir
defmodule Target do
  use Reather

  reather foo(a, b) do
    x <- bar(a) # The result of bar(a) is {:ok, a + 1} and x will be bound to a + 1.

    x + b
  end

  reather bar(a), do: a + 1
end

iex> Target.foo(1, 1) |> Reather.run()
{:ok, 3}
```

Because of the either monad, when the `<-` operator meets the error tuple,
the reather will return immediately.

```elixir
defmodule Target do
  use Reather

  reather foo() do
    x <- {:ok, 1}
    y <- {:error, "asdf", 1} # foo will return {:error, {"asdf", 1}}

    x + y
  end
end

iex> Target.foo() |> Reather.run()
{:error, {"asdf", 1}}
```

### Inline `reather`

`reather` also can be inlined.

```elixir
iex> r =
...>   reather do
...>     x <- {:ok, 1}
...>     y <- {:ok, 2}
...>
...>     x + y
...>   end
%Reather{...}

iex> r |> Reather.run()
{:ok, 3}
```

### `Reather.ask`

Because of the `Reather` is a combination of reader and either monads,
it also provide an environment.

The providen environment can be accessed with `Reather.ask/0`.

```elixir
defmodule Target do
  use Reather

  reather foo() do
    %{a: a} <- Reather.ask()
    %{b: b} <- Reather.ask()
    1 + a + b
  end

  reather bar() do
    x <- foo()

    x + 1
  end
end

iex> Target.foo() |> Reather.run(%{a: 10, b: 100})
{:ok, 111}

# The environment can be accessed in nested reathers.
iex> Target.bar() |> Reather.run(%{a: 10, b: 100})
{:ok, 112}
```

### `reatherp`

If you want to define a private reather, use `reatherp` macro instead.

```elixir
defmodule Target do
  use Reather

  reatherp foo() do
    1
  end
end
```
