defmodule Reather.Either do
  @doc """
  Convert the value with `ok` or `error` tuple.

  ## Examples
      iex> Reather.Either.new(:ok)
      {:ok, nil}
      iex> Reather.Either.new(:error)
      {:error, nil}
      iex> Reather.Either.new({:ok, 3})
      {:ok, 3}
      iex> Reather.Either.new({:error, "error!"})
      {:error, "error!"}
      iex> Reather.Either.new({:ok, 1, 2})
      {:ok, {1, 2}}
      iex> Reather.Either.new({:error, "error", :invalid})
      {:error, {"error", :invalid}}
      iex> Reather.Either.new({1, 2})
      {:ok, {1, 2}}
      iex> Reather.Either.new({})
      {:ok, {}}
      iex> Reather.Either.new(1)
      {:ok, 1}
      iex> [1, :error]
      ...> |> Enum.map(fn x ->
      ...>   Reather.Either.new(x, "error")
      ...> end)
      [{:ok, 1}, {:error, "error"}]
  """
  def new(v, err \\ nil) do
    case v do
      :error ->
        {:error, err}

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

  def error(v), do: {:error, v}

  def map({:ok, value}, fun) do
    {:ok, fun.(value)}
  end

  def map({:error, err}, _) do
    {:error, err}
  end

  def traverse(traversable) when is_list(traversable) do
    Enum.reduce_while(traversable, [], fn
      {:ok, v}, acc -> {:cont, [v | acc]}
      {:error, err}, _acc -> {:halt, {:error, err}}
    end)
    |> case do
      {:error, _} = e -> e
      vs -> {:ok, Enum.reverse(vs)}
    end
  end
end
