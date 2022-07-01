defmodule Reather do
  defstruct [:reather]

  @moduledoc """
  Reather is the combined form of Reader and Either monad.
  A `Reather` wrapps an environment and the child functions can
  use the environment to access the values.

  The evaluation of `Reather` is lazy, so it's never computed until
  explicitly call `Reather.run/2`.
  """

  defmacro __using__([]) do
    quote do
      import Reather.Macros, only: [reather: 1, reather: 2, reatherp: 2]
      require Reather.Macros
    end
  end

  @doc """
  Get the current environment.
  """
  def ask(), do: Reather.new(fn env -> {:ok, env} end)

  @doc """
  Run the reather.
  """
  def run(%Reather{reather: fun}, arg \\ %{}) do
    fun.(arg)
  end

  @doc """
  Inspect the reather.

  **Warning**: It _runs_ the reather. So, the provided
  reather should not have side effects.
  """
  def inspect(%Reather{} = r, opts \\ []) do
    Reather.new(fn env ->
      r |> Reather.run(env) |> IO.inspect(opts)
    end)
  end

  @doc """
  Create a new `Reather` from the function.
  """
  def new(fun), do: %Reather{reather: fun}

  @doc """
  Wrap the value with `ok` or `error` tuple.
  If it is already wrapped, it will be returned as is.
  """
  def either(v) do
    case v do
      {:error, _} = error -> error
      {:ok, _} = ok -> ok
      value -> {:ok, value}
    end
  end

  @doc """
  Create a `Reather` from the value.
  """
  def of(v), do: Reather.new(fn _ -> either(v) end)

  @doc """
  Create a `Reather` from the value.
  If the value is `Reather`, it will be returned as is.
  """
  def wrap(%Reather{} = r), do: r
  def wrap(v), do: of(v)
end
