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
  Convert the value with `ok` or `error` tuple.

  ## Examples
      iex> Reather.either(:ok)
      {:ok, nil}
      iex> Reather.either(:error)
      {:error, nil}
      iex> Reather.either({:ok, 3})
      {:ok, 3}
      iex> Reather.either({:error, "error!"})
      {:error, "error!"}
      iex> Reather.either({:ok, 1, 2})
      {:ok, {1, 2}}
      iex> Reather.either({:error, "error", :invalid})
      {:error, {"error", :invalid}}
      iex> Reather.either({1, 2})
      {:ok, {1, 2}}
      iex> Reather.either({})
      {:ok, {}}
      iex> Reather.either(1)
      {:ok, 1}
  """
  def either(v) do
    case v do
      :error ->
        {:error, nil}

      {:error, _} = error ->
        error

      :ok ->
        {:ok, nil}

      {:ok, _} = ok ->
        ok

      value when is_tuple(value) and tuple_size(value) > 0 ->
        case elem(value, 0) do
          result when result in [:ok, :error] ->
            {result, Tuple.delete_at(value, 0)}

          _ ->
            {:ok, value}
        end

      value ->
        {:ok, value}
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
