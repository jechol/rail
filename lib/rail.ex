defmodule Rail do
  defmacro __using__(opts) do
    overrides =
      if Keyword.get(opts, :override_kernel, true) do
        [def: 2, defp: 2]
      else
        []
      end

    quote do
      import Kernel, except: unquote(overrides)

      import Rail,
        only: unquote([rail: 1, rail: 2, railp: 2, >>>: 2, map_ok: 2, map_error: 2] ++ overrides)
    end
  end

  defmacro rail(head, body) do
    expanded_body = expand_body(body)

    quote do
      def unquote(head), unquote(expanded_body)
    end
  end

  defmacro def(head, body) do
    quote do
      rail unquote(head), unquote(body)
    end
  end

  defmacro railp(head, body) do
    expanded_body = expand_body(body)

    quote do
      defp unquote(head), unquote(expanded_body)
    end
  end

  defmacro defp(head, body) do
    quote do
      railp unquote(head), unquote(body)
    end
  end

  defmacro rail([do: _] = body) do
    [do: result] = expand_body(body)
    result
  end

  # Private

  defp expand_body([{:do, do_block} | rest]) do
    [{:do, expand_do_block(do_block)} | rest]
  end

  defp expand_do_block({:__block__, _ctx, exprs}) do
    parse_exprs(exprs)
  end

  defp expand_do_block(expr) do
    parse_exprs([expr])
  end

  defp parse_exprs(exprs) do
    {body, ret} = Enum.split(exprs, -1)

    wrapped_ret =
      quote do
        unquote(List.first(ret))
      end

    List.foldr(body, wrapped_ret, fn
      {:<-, _ctx, [lhs, rhs]}, acc ->
        quote do
          Rail.chain(unquote(rhs), fn unquote(lhs) -> unquote(acc) end)
        end

      expr, acc ->
        quote do
          unquote(expr)
          unquote(acc)
        end
    end)
  end

  @doc """
  Apply a function when value is not {:error, _} or :error

  ## Examples

      iex> 1 |> Rail.chain(fn v -> v + 10 end)
      11
      iex> {:ok, 1} |> Rail.chain(fn v -> v + 10 end)
      11
      iex> :error |> Rail.chain(fn v -> v + 10 end)
      :error
      iex> {:error, :noent} |> Rail.chain(fn v -> v + 10 end)
      {:error, :noent}

  """
  @spec chain(any, (any -> any)) :: any
  def chain({:error, _} = error, _) do
    error
  end

  def chain(:error = error, _) do
    error
  end

  def chain({:ok, value}, fun) when is_function(fun, 1) do
    fun.(value)
  end

  def chain(value, fun) when is_function(fun, 1) do
    fun.(value)
  end

  @doc """
  Apply a function or pipe to a function call when value is not {:error, _} or :error

  ## Examples

      iex> 1 >>> fn v -> Integer.to_string(v) end
      "1"
      iex> {:ok, 1} >>> fn v -> Integer.to_string(v) end
      "1"
      iex> {:ok, 1} >>> Integer.to_string()
      "1"
      iex> :error >>> Integer.to_string()
      :error
      iex> {:error, :div_by_zero} >>> Integer.to_string()
      {:error, :div_by_zero}

  """

  defmacro value >>> ({:fn, _, _} = fun) do
    # anonymous function
    handle_function(value, fun)
  end

  defmacro value >>> ({:&, _, _} = fun) do
    # captured function
    handle_function(value, fun)
  end

  defmacro value >>> {{:., _, _} = fun, ctx, args} do
    # pipe style remote call
    handle_call(value, {fun, ctx, args})
  end

  defmacro value >>> {fun, ctx, args} when is_atom(fun) do
    # pipe style local or imported call

    args =
      if args in [nil, Elixir] do
        # called without parens
        # ex: 1 >>> to_string
        []
      else
        args
      end

    handle_call(value, {fun, ctx, args})
  end

  defmacro value >>> fun do
    # other
    handle_function(value, fun)
  end

  defp handle_function(value, fun) do
    quote do
      Rail.chain(unquote(value), unquote(fun))
    end
  end

  defp handle_call(value, {fun, ctx, args}) do
    # called like pipe style.
    # ex. {:ok, 1} >>> Integer.to_string()

    v = Macro.var(:v, __MODULE__)

    quote do
      Rail.chain(unquote(value), fn unquote(v) ->
        unquote({fun, ctx, [v | args]})
      end)
    end
  end

  @doc """
  Apply a function for value of {:ok, value}, otherwise bypass

  ## Examples

      iex> :ok |> Rail.map_ok(fn 1 -> 10 end)
      :ok
      iex> {:ok, 1} |> Rail.map_ok(fn 1 -> 10 end)
      {:ok, 10}
      iex> {:error, 1} |> Rail.map_ok(fn 1 -> 10 end)
      {:error, 1}

  """
  def map_ok({:ok, value}, fun) when is_function(fun, 1), do: {:ok, fun.(value)}
  def map_ok(other, _), do: other

  @doc """
  Apply a function for error of {:error, error}, otherwise bypass

  ## Examples

      iex> :error |> Rail.map_error(fn :noent -> :not_found end)
      :error
      iex> {:error, :noent} |> Rail.map_error(fn :noent -> :not_found end)
      {:error, :not_found}

  """
  def map_error({:error, value}, fun) when is_function(fun, 1), do: {:error, fun.(value)}
  def map_error(other, _), do: other

  @doc """
  Normalize input to {:ok, value} or {:error, error}

  ## Examples

      iex> :error |> Rail.normalize()
      {:error, nil}
      iex> {:error, 1, 2} |> Rail.normalize()
      {:error, {1, 2}}
      iex> :ok |> Rail.normalize()
      {:ok, nil}
      iex> {:ok, 1, 2} |> Rail.normalize()
      {:ok, {1, 2}}
      iex> {:hello, :world} |> Rail.normalize()
      {:ok, {:hello, :world}}

  """

  def normalize(tag) when tag in [:ok, :error], do: {tag, nil}
  def normalize({tag, v1}) when tag in [:ok, :error], do: {tag, v1}
  def normalize({tag, v1, v2}) when tag in [:ok, :error], do: {tag, {v1, v2}}
  def normalize({tag, v1, v2, v3}) when tag in [:ok, :error], do: {tag, {v1, v2, v3}}
  def normalize({tag, v1, v2, v3, v4}) when tag in [:ok, :error], do: {tag, {v1, v2, v3, v4}}
  def normalize(untagged), do: {:ok, untagged}
end
