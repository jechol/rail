defmodule Reather do
  defstruct [:reather]

  require Reather.Macros
  import Reather.Macros
  alias Reather.Either

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
      alias Reather.Either
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
  Map the function to the reather.

  `map` is lazy, so it's never computed until explicitly call
  `Reather.run/2`.

      iex> r = reather do
      ...>       x <- {:ok, 1}
      ...>       x
      ...>     end
      iex> r
      ...> |> Reather.map(fn x -> x + 1 end)
      ...> |> Reather.run()
      {:ok, 2}
  """
  def map(r, fun) do
    reather do
      x <- r

      fun.(x)
    end
  end

  def traverse(traversable) when is_list(traversable) do
    Reather.new(fn env ->
      traversable
      |> Enum.map(fn %Reather{} = r ->
        Reather.run(r, env)
      end)
      |> Either.traverse()
    end)
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
  Create a `Reather` from the value.
  """
  def of(v), do: Reather.new(fn _ -> Either.new(v) end)

  @doc """
  Create a `Reather` from the value.
  If the value is `Reather`, it will be returned as is.

  ## Example
      iex> %Reather{} = Reather.wrap(:ok)

      iex> r = %Reather{}
      iex> ^r = Reather.wrap(r)
  """
  def wrap(%Reather{} = r), do: r
  def wrap(v), do: of(v)
end
