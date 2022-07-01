defmodule Reather do
  alias Reather.{Left, Right}
  defstruct [:reather]

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

  def of(either) do
    case either do
      %Left{} = left ->
        Reather.new(fn _env -> left end)

      %Right{} = right ->
        Reather.new(fn _env -> right end)

      value ->
        Reather.new(fn _env -> %Right{right: value} end)
    end
  end

  def wrap(%Reather{} = r), do: r
  def wrap(v), do: of(v)
end
