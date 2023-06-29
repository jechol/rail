defmodule Rail do
  require Logger

  @overrides [def: 2, defp: 2]

  defmacro __using__(opts) do
    def_provider = opts |> Keyword.get(:def_provider, Kernel)

    Module.put_attribute(__CALLER__.module, :def_provider, def_provider)
    # Logger.error("Module.put_attribute(#{__CALLER__.module}, :def_provider, #{def_provider})")

    quote do
      import Kernel, except: unquote(@overrides)

      import Rail,
        only: unquote([rail: 1, rail: 2, railp: 2, >>>: 2, map_ok: 2, map_error: 2] ++ @overrides)
    end
  end

  @doc """
  Similar to `Kernel.def/2`, but the function body is wrapped in a `rail/1` block.

  ```elixir
  defmodule Target do
    use Rail

    rail sum() do
      x <- {:ok, 1}
      y <- {:ok, 1}

      {:ok, x + y}
    end
  end
  ```
  """
  defmacro rail(head, body) do
    def_provider = Module.get_attribute(__CALLER__.module, :def_provider, Kernel)
    # Logger.warn("Module.get_attribute(#{__CALLER__.module}, :def_provider): #{def_provider}")

    expanded_body = expand_body(body)

    quote do
      require unquote(def_provider)
      unquote(def_provider).def(unquote(head), unquote(expanded_body))
    end
  end

  @doc """
  Similar to `Kernel.def/2`, but the function body is wrapped in a `rail/1` block.

  ```elixir
  defmodule Target do
    use Rail

    def sum() do
      x <- {:ok, 1}
      y <- {:ok, 1}

      {:ok, x + y}
    end
  end
  ```
  """
  defmacro def(head, body) do
    quote do
      Rail.rail(unquote(head), unquote(body))
    end
  end

  @doc """
  Similar to `Kernel.defp/2`, but the function body is wrapped in a `rail/1` block.

  ```elixir
  defmodule Target do
    use Rail

    rail sum() do
      x <- {:ok, 1}
      y <- {:ok, 1}

      {:ok, x + y}
    end
  end
  ```
  """
  defmacro railp(head, body) do
    def_provider = Module.get_attribute(__CALLER__.module, :def_provider, Kernel)
    # Logger.warn("Module.get_attribute(#{__CALLER__.module}, :def_provider): #{def_provider}")

    expanded_body = expand_body(body)

    quote do
      require unquote(def_provider)
      unquote(def_provider).defp(unquote(head), unquote(expanded_body))
    end
  end

  @doc """
  Similar to `Kernel.defp/2`, but the function body is wrapped in a `rail/1` block.

  ```elixir
  defmodule Target do
    use Rail

    defp sum() do
      x <- {:ok, 1}
      y <- {:ok, 1}

      {:ok, x + y}
    end
  end
  ```
  """
  defmacro defp(head, body) do
    quote do
      Rail.railp(unquote(head), unquote(body))
    end
  end

  @doc """

  Introduces new syntax `left <- right`,

  - which bind `value` to left when `right` is `{:ok, value}` or just `value`
  - or skips entire code block when `right` is `{:error, _}` or `:error`.


  ## Examples

      iex> rail do
      ...>   x <- {:ok, 1}
      ...>   y <- {:ok, 2}
      ...>
      ...>   x + y
      ...> end
      3

  """
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
    report(error)
    error
  end

  def chain(:error = error, _) do
    report(error)
    error
  end

  def chain({:ok, value}, fun) when is_function(fun, 1) do
    fun.(value)
  end

  def chain(value, fun) when is_function(fun, 1) do
    fun.(value)
  end

  defp report(error) do
    reported = Process.get(:rail_reported_errors, [])

    if Enum.member?(reported, error) do
      {:ok, :already_reported}
    else
      reporter = Process.get(:rail_error_reporter) || Application.get_env(:rail, :error_reporter)

      if reporter do
        {:current_stacktrace, [{Process, _, _, _} | trace] = _trace} =
          Process.info(self(), :current_stacktrace)

        trace = trace |> Enum.filter(fn tuple -> tuple |> elem(0) != Rail end)

        case reporter do
          {module, function, 2} when is_atom(module) and is_atom(function) ->
            apply(module, function, [error, trace])

          module when is_atom(module) ->
            apply(module, :report_error, [error, trace])

          f when is_function(f, 2) ->
            f.(error, trace)
        end
      else
        {:ok, :no_handler}
      end

      Process.put(:rail_reported_errors, [error | reported])
      {:ok, :reported}
    end
  end

  defmodule ErrorReporter do
    @callback report_error(any, any) :: :ok
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
