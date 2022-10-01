defmodule Reather.Macros do
  @doc """
  Declare a reather.
  """
  defmacro reather(head, body) do
    built_body = build_body(body)

    quote do
      with {line, doc} when is_bitstring(doc) <- Module.get_attribute(__MODULE__, :doc) do
        Module.put_attribute(
          __MODULE__,
          :doc,
          Reather.Macros.decorate_doc({line, doc})
        )
      end

      def unquote(head) do
        unquote(built_body)
      end
    end
  end

  defmacro reather(body) do
    build_body(body)
  end

  def build_body(body) do
    # Elixir function body is implicit try.
    # So we need to wrap the body with try to support do, else, rescue, catch and after.
    {[do: do_block], rest} = body |> Keyword.split([:do])
    built_do_block = build_do_block(do_block)

    run_do_block =
      quote do
        unquote(built_do_block) |> Reather.run(env)
      end

    # If try doesn't have any one of rescue, catch and after, then compiler warns to use `case` instead.
    # So, insert empty `after` block to avoid the warning.
    {after_block, rest} =
      case rest |> Keyword.split([:after]) do
        {[after: after_block], rest} -> {after_block, rest}
        {[], rest} -> {{:__block__, [], []}, rest}
      end

    quote do
      Reather.new(fn env ->
        unquote({:try, [], [[do: run_do_block] ++ rest ++ [after: after_block]]})
      end)
    end
  end

  @doc """
  Declare a private reather.
  """
  defmacro reatherp(head, body) do
    built_body = build_body(body)

    quote do
      defp unquote(head) do
        unquote(built_body)
      end
    end
  end

  defp build_do_block({:__block__, _ctx, exprs}) do
    parse_exprs(exprs)
  end

  defp build_do_block(expr) do
    parse_exprs([expr])
  end

  defp build_match(lhs, acc) do
    quote do
      {:ok, unquote(lhs)} ->
        unquote(acc)
        |> Reather.run(env)

      {:error, _} = error ->
        error
    end
  end

  defp parse_exprs(exprs) do
    [ret | body] = exprs |> Enum.reverse()

    wrapped_ret =
      quote do
        Reather.new(fn _ -> Reather.Either.new(unquote(ret)) end)
      end

    body
    |> List.foldl(wrapped_ret, fn
      {:<-, _ctx, [lhs, rhs]}, acc ->
        match = build_match(lhs, acc)

        quote do
          unquote(rhs)
          |> Reather.wrap()
          |> (fn %Reather{} = r ->
                fn env ->
                  r
                  |> Reather.run(env)
                  |> case do
                    unquote(match)
                  end
                end
                |> Reather.new()
              end).()
        end

      expr, acc ->
        quote do
          unquote(expr)
          unquote(acc)
        end
    end)
  end

  def decorate_doc({line, doc}) do
    {line, "### (Reather)\n\n" <> doc}
  end
end
