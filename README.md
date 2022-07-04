# ReatherLite

[![test](https://github.com/SeokminHong/reather_lite/actions/workflows/test.yml/badge.svg)](https://github.com/SeokminHong/reather_lite/actions/workflows/test.yml)
[![Coverage Status](https://coveralls.io/repos/github/SeokminHong/reather-lite/badge.svg?branch=main)](https://coveralls.io/github/SeokminHong/reather-lite?branch=main)
[![Hex.pm](https://img.shields.io/hexpm/v/reather_lite)](https://hex.pm/packages/reather_lite)
[![GitHub](https://img.shields.io/github/license/SeokminHong/reather-lite)](https://github.com/SeokminHong/reather-lite/blob/main/LICENSE)

`Reather` is a shortcut of `Reader` + `Either` monads pattern.

It makes you define and unwrap the `Reather` easiliy by using the `reather` macro.

The original idea is from [jechol/reather](https://github.com/jechol/reather), and this is a
lite version without using [Witchcraft](https://witchcrafters.github.io/).

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

Since the `Reather` is lazily evaluated, it does nothing until call `Reather.run/2`.

```elixir
iex> Target.foo(1, 1) |> Reather.run()
{:ok, 2}
```

The result of `Reather` is always `{:ok, value}` or `{:error, error}`.

In a `reather` block, the `ok` tuple will be automatically unwrapped by a `<-` operator.

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

Also, a `Reather` unwrap into a value with a `<-` operator.

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

Because of the either monad, when the `<-` operator meets an error tuple,
the reather will return it immediately.

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
it also provides an environment.

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

### `Reather.map`

You can `map` a function to a `Reather`.
The given function will be applied lazily when the result of
the reather is an `ok` tuple.

```elixir
defmodule Target do
  use Reather

  reather foo() do
    x <- {:ok, 1}

    x
  end

  reather bar() do
    x <- {:error, 1}

    x
  end
end

iex> Target.foo()
...> |> Reather.map(fn x -> x + 1 end)
...> |> Reather.run()
{:ok, 2}

iex> Target.bar()
...> |> Reather.map(fn x -> x + 1 end)
...> |> Reather.run()
{:error, 1}
```

## LICENSE

[MIT](./LICENSE)
