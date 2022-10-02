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

  defp build_body([{:do, do_block} | rest]) do
    built_do_block = build_do_block(do_block)
    run_do_block = quote do: unquote(built_do_block) |> Reather.run(env)

    case rest do
      [] ->
        # no need to wrap
        quote do
          Reather.new(fn env -> unquote(run_do_block) end)
        end

      [else: matches] ->
        # wrap with case
        quote do
          Reather.new(fn env ->
            unquote(run_do_block)
            |> case do
              unquote(matches)
            end
          end)
        end

      rest ->
        # Elixir function body is implicit try.
        # So we need to wrap the body with try to support do, else, rescue, catch and after.
        quote do
          Reather.new(fn env ->
            unquote({:try, [], [[do: run_do_block] ++ rest]})
          end)
        end
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

  defp parse_exprs(exprs) do
    {body, ret} = Enum.split(exprs, -1)

    wrapped_ret =
      quote do
        unquote(List.first(ret)) |> Reather.wrap()
      end

    body
    |> List.foldr(wrapped_ret, fn
      {:<-, _ctx, [lhs, rhs]}, acc ->
        quote do
          unquote(rhs)
          |> Reather.wrap()
          |> Reather.chain(fn unquote(lhs) -> unquote(acc) end)
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
