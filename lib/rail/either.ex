defmodule Rail.Either do
  @type ok(t) :: {:ok, t}
  @type error(t) :: {:error, t}
  @type either(t) :: ok(t) | error(any)

  @type ok_like :: any
  @type error_like :: any
  @type either_like :: ok_like | error_like

  @doc """
  Convert a value into `ok` or `error` tuple. The result is a tuple having
  an `:ok` or `:error` atom for the first element, and a value for the second
  element.

  ## Examples
      iex> Either.new(:ok)
      {:ok, nil}
      iex> Either.new(:error)
      {:error, nil}
      iex> Either.new({:ok, 3})
      {:ok, 3}
      iex> Either.new({:error, "error!"})
      {:error, "error!"}
      iex> Either.new({:ok, 1, 2})
      {:ok, {1, 2}}
      iex> Either.new({:error, "error", :invalid})
      {:error, {"error", :invalid}}
      iex> Either.new({1, 2})
      {:ok, {1, 2}}
      iex> Either.new({})
      {:ok, {}}
      iex> Either.new(1)
      {:ok, 1}
  """
  @spec new(any) :: either_like
  def new(:ok), do: {:ok, nil}
  def new(:error), do: {:error, nil}
  def new({:ok, v}), do: {:ok, v}
  def new({:error, v}), do: {:error, v}

  def new(v) when is_tuple(v) and tuple_size(v) > 0 do
    case elem(v, 0) do
      result when result in [:ok, :error] ->
        {result, Tuple.delete_at(v, 0)}

      _ ->
        {:ok, v}
    end
  end

  def new(v), do: {:ok, v}

  @doc """
  Wrap a value with an ok tuple.

  ## Examples
      iex> Either.ok(1)
      {:ok, 1}
      iex> Either.ok({:error, 1})
      {:ok, {:error, 1}}
  """
  @spec ok(t) :: ok(t) when t: any
  def ok(v), do: {:ok, v}

  @doc """
  Wrap a value with an error tuple.

  ## Examples
      iex> Either.error(1)
      {:error, 1}
      iex> Either.error({:ok, 1})
      {:error, {:ok, 1}}
  """
  @spec error(t) :: error(t) when t: any
  def error(v), do: {:error, v}

  @doc """
  Unwrap a value from an ok tuple.

  ## Examples
      iex> Either.unwrap({:ok, 1})
      1
      iex> Either.unwrap({:error, 1})
      ** (RuntimeError) 1
      iex> Either.unwrap({:ok, 1, 2, 3})
      {1, 2, 3}
  """
  @spec unwrap(ok_like) :: any
  def unwrap({:ok, v}), do: v
  def unwrap({:error, v}), do: raise(RuntimeError, v |> inspect())
  def unwrap(v), do: new(v) |> unwrap()

  @doc """
  Unwrap a value from an ok tuple.
  If the value is an error tuple, use passed default value or function.

  ## Examples
      iex> Either.unwrap_or({:ok, 1}, 0)
      1
      iex> Either.unwrap_or({:error, ""}, 0)
      0
      iex> Either.unwrap_or({:error, ""}, fn -> "default" end)
      "default"
      iex> Either.unwrap_or(:error, "hello")
      "hello"
  """
  @spec unwrap_or(either_like, t | (() -> t)) :: t when t: any
  def unwrap_or({:ok, v}, _), do: v
  def unwrap_or({:error, _}, f) when is_function(f), do: f.()
  def unwrap_or({:error, _}, default), do: default
  def unwrap_or(v, default), do: new(v) |> unwrap_or(default)

  @doc """
  Check if the value is an ok tuple.

  ## Examples
      iex> Either.ok?({:ok, 1})
      true
      iex> Either.ok?(:ok)
      true
      iex> Either.ok?({:error, 1})
      false
      iex> Either.ok?(:error)
      false
  """
  @spec ok?(either_like) :: boolean
  def ok?({:ok, _}), do: true
  def ok?({:error, _}), do: false
  def ok?(v), do: new(v) |> ok?()

  @doc """
  Create a either from a boolean.

  ## Examples
      iex> Either.confirm(true)
      {:ok, nil}
      iex> Either.confirm(false, :value_error)
      {:error, :value_error}
  """
  @spec confirm(boolean, t) :: either(t) when t: any
  def confirm(boolean, err \\ nil)
  def confirm(true, _), do: {:ok, nil}
  def confirm(false, err), do: {:error, err}

  @doc """
  Map a function to the either.
  If the either is `ok`, the function is applied to the value.
  If the either is `error`, it returns as is.

  ## Examples
      iex> {:ok, 1} |> Either.map(fn x -> x + 1 end)
      {:ok, 2}
      iex> {:error, 1} |> Either.map(fn x -> x + 1 end)
      {:error, 1}
      iex> :ok |> Either.map(fn _ -> 1 end)
      {:ok, 1}
  """
  @spec map(either_like, (any -> t)) :: either(t) when t: any
  def map({:ok, value}, fun) do
    {:ok, fun.(value)}
  end

  def map({:error, err}, _) do
    {:error, err}
  end

  def map(v, fun) do
    new(v) |> map(fun)
  end

  @doc """
  Map a function to the `error` tuple.

  ## Examples
      iex> {:error, 1} |> Either.map_err(fn x -> x + 1 end)
      {:error, 2}
      iex> {:ok, 1} |> Either.map_err(fn x -> x + 1 end)
      {:ok, 1}
      iex> :error |> Either.map_err(fn _ -> 1 end)
      {:error, 1}
  """
  @spec map_err(either_like, (any -> t)) :: either(t) when t: any
  def map_err({:ok, v}, _), do: {:ok, v}
  def map_err({:error, v}, fun), do: {:error, fun.(v)}
  def map_err(v, map), do: new(v) |> map_err(map)

  @doc """
  Transform a list of eithers to an either of a list.
  If any of the eithers is `error`, the result is `error`.

  ## Examples
      iex> [{:ok, 1}, {:ok, 2}] |> Either.traverse()
      {:ok, [1, 2]}
      iex> [{:ok, 1}, {:error, "error!"}, {:ok, 2}]
      ...> |> Either.traverse()
      {:error, "error!"}
  """
  @spec traverse([either_like]) :: either([any])
  def traverse(traversable) when is_list(traversable) do
    traversable
    |> Enum.map(&new(&1))
    |> Enum.reduce_while([], fn
      {:ok, v}, acc -> {:cont, [v | acc]}
      {:error, err}, _acc -> {:halt, {:error, err}}
    end)
    |> case do
      {:error, _} = e -> e
      vs -> {:ok, Enum.reverse(vs)}
    end
  end
end
