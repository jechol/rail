# Rail

[![test](https://github.com/jechol/rail/actions/workflows/test.yml/badge.svg)](https://github.com/jechol/rail/actions/workflows/test.yml)
[![Coverage Status](https://coveralls.io/repos/github/jechol/rail/badge.svg?branch=main)](https://coveralls.io/github/jechol/rail?branch=main)
[![Hex.pm](https://img.shields.io/hexpm/v/rail)](https://hex.pm/packages/rail)
[![GitHub](https://img.shields.io/github/license/jechol/rail)](https://github.com/jechol/rail/blob/main/LICENSE)

`Rail` is a helper macros for "Railway oriented programming".

It helps you handle error cases at almost no cost with `rail` macro.

If you are not comfortable with "Railway oriented programming", see [Railway oriented programming](https://www.youtube.com/watch?v=fYo3LN9Vf_M)

This library is mostly copied from [SeokminHong/reather-lite](https://github.com/SeokminHong/reather-lite) and removed reader monad related stuffs to lower learning curve.

## Installation

```elixir
def deps do
  [
    {:rail, "~> 0.2.0"}
  ]
end
```

## Usage

### Basic usage

`use Rail` introduces new syntax `left <- right`,

- which bind `value` to left when right is `{:ok, value}` or `value`
- or skips entire code block when right is `{:error, err}` or `:error`.

```elixir

defmodule Target do
  use Rail

  def div(num, denom) do
    denom <- check_denom(denom)
    num / denom
  end

  def check_denom(0) do
    {:error, :div_by_zero}
  end

  def check_denom(n) do
    # same with {:ok, n}
    n
  end
end

iex> Calc.div(10, 2)
5.0
iex> Calc.div(10, 0)
{:error, :div_by_zero}
```

`rail/1` is available inside other code blocks.

```elixir

iex> rail do
...    x <- {:ok, 1}
...    y <- {:ok, 2}
...
...    x + y
...  end
3
```

## LICENSE

[MIT](./LICENSE)
