defmodule Reather do
  defstruct [:reather]

  defmacro __using__([]) do
    quote do
      import Reather.Macros, only: [reather: 1, reather: 2, reatherp: 2]
      require Reather.Macros
    end
  end

  def ask(), do: Reather.new(fn env -> ok(env) end)

  def run(%Reather{reather: fun}, arg \\ %{}) do
    fun.(arg)
  end

  def inspect(%Reather{} = r, opts \\ []) do
    Reather.new(fn env ->
      r |> Reather.run(env) |> IO.inspect(opts)
    end)
  end

  def error(error), do: {:error, error}

  def ok(value), do: {:ok, value}

  def new(fun), do: %Reather{reather: fun}

  def either(v) do
    case v do
      {:error, _} = error -> error
      {:ok, _} = ok -> ok
      value -> {:ok, value}
    end
  end

  def of(v), do: Reather.new(fn _ -> either(v) end)

  def wrap(%Reather{} = r), do: r
  def wrap(v), do: of(v)
end
