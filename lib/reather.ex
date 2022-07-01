defmodule Reather do
  alias Reather.{Left, Right}
  defstruct [:reather]

  defmacro __using__([]) do
    quote do
      import Reather.Macros, only: [reather: 2, reatherp: 2]
      require Reather.Macros
      alias Reather.{Left, Right}
    end
  end

  def ask(), do: Reather.new(fn env -> right(env) end)

  def run(%Reather{reather: fun}, arg \\ %{}) do
    fun.(arg)
  end

  def inspect(%Reather{} = r, opts \\ []) do
    Reather.new(fn env ->
      r |> Reather.run(env) |> IO.inspect(opts)
    end)
  end

  def left(error), do: %Left{left: error}

  def right(value), do: %Right{right: value}

  def new(fun), do: %Reather{reather: fun}

  def either(v) do
    case v do
      %Left{} = left -> left
      %Right{} = right -> right
      value -> %Right{right: value}
    end
  end

  def of(v), do: Reather.new(fn _ -> either(v) end)

  def wrap(%Reather{} = r), do: r
  def wrap(v), do: of(v)
end
