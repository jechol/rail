# Rail

[![test](https://github.com/jechol/rail/actions/workflows/test.yml/badge.svg)](https://github.com/jechol/rail/actions/workflows/test.yml)
[![Coverage Status](https://coveralls.io/repos/github/jechol/rail/badge.svg?branch=main)](https://coveralls.io/github/jechol/rail?branch=main)
[![Hex.pm](https://img.shields.io/hexpm/v/rail)](https://hex.pm/packages/rail)
[![GitHub](https://img.shields.io/github/license/jechol/rail)](https://github.com/jechol/rail/blob/main/LICENSE)

`Rail` is a helper macros for "Railway oriented programming".

It helps you handle error cases at almost no cost with `rail`, `>>>`, and `def` macro.

If you are not comfortable with "Railway oriented programming", see [Railway oriented programming](https://www.youtube.com/watch?v=fYo3LN9Vf_M)

## Installation

```elixir
def deps do
  [
    {:rail, "~> 0.9.1"}
  ]
end
```

## Usage

### Basic usage

`use Rail` introduces new syntax `left <- right`,

- which bind `value` to left when right is `{:ok, value}` or `value`
- or skips entire code block when right is `{:error, _}` or `:error`.

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

`left >>> right` is similar to `|>`, but

- applies right function only when left is `value` or `{:ok, value}`.
- support both function and call expression, which makes it compatible with `|>`.

```elixir
iex> 1 >>> fn v -> Integer.to_string(v) end
"1"
iex> {:ok, 1} >>> fn v -> Integer.to_string(v) end
"1"
iex> {:ok, 1} >>> Integer.to_string()
"1"
iex> {:error, :div_by_zero} >>> Integer.to_string()
{:error, :div_by_zero}
```

For more examples, see `Rail`

## LICENSE

[MIT](./LICENSE)
