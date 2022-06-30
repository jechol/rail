defmodule Reather do
  alias Reather.{Left, Right}
  defstruct [:reather]

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

  def ask, do: Reather.new(fn env -> right(env) end)

  def run(%Reather{reather: fun}, arg \\ %{}) do
    fun.(arg)
  end
end
