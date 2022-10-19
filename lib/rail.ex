defmodule Rail do
  defmacro __using__(opts) do
    override_def = Keyword.get(opts, :override_def, true)

    common =
      quote do
      end

    if override_def do
      quote do
        import Kernel, except: [def: 2, defp: 2]
        import Rail, only: [def: 2, defp: 2, rail: 1, rail: 2, railp: 2, >>>: 2]
        unquote(common)
      end
    else
      quote do
        import Rail, only: [rail: 1, rail: 2, railp: 2, >>>: 2]
        unquote(common)
      end
    end
  end

  alias Rail.Either

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

    body
    |> List.foldr(wrapped_ret, fn
      {:<-, _ctx, [lhs, rhs]}, acc ->
        quote do
          unquote(rhs) |> Rail.chain(fn unquote(lhs) -> unquote(acc) end)
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

  def chain({:ok, value}, chain_fun) when is_function(chain_fun, 1) do
    value |> chain_fun.()
  end

  def chain(value, chain_fun) when is_function(chain_fun, 1) do
    value |> chain_fun.()
  end

  @doc """
  Apply a function or pipe to a function call when value is not {:error, _} or :error

  ## Examples

      iex> {:ok, 1} >>> fn v -> Integer.to_string(v) end
      "1"
      iex> {:ok, 1} >>> Integer.to_string()
      "1"
      iex> :error >>> Integer.to_string()
      :error
      iex> {:error, :div_by_zero} >>> Integer.to_string()
      {:error, :div_by_zero}

  """
  defdelegate value >>> chain_fun, to: __MODULE__, as: :chain
end
