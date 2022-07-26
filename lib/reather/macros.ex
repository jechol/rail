defmodule Reather.Macros do
  @doc """
  Declare a reather.
  """
  defmacro reather(head, body) do
    do_body = Keyword.get(body, :do)
    else_body = Keyword.get(body, :else)
    built_body = build_body(do_body, else_body)

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
    do_body = Keyword.get(body, :do)
    else_body = Keyword.get(body, :else)
    build_body(do_body, else_body)
  end

  @doc """
  Declare a private reather.
  """
  defmacro reatherp(head, body) do
    do_body = Keyword.get(body, :do)
    else_body = Keyword.get(body, :else)
    built_body = build_body(do_body, else_body)

    quote do
      defp unquote(head) do
        unquote(built_body)
      end
    end
  end

  defp build_body({:__block__, _ctx, exprs}, else_body) do
    parse_exprs(exprs, else_body)
  end

  defp build_body(expr, else_body) do
    parse_exprs([expr], else_body)
  end

  defp build_match(lhs, acc, else_body) do
    [ok | err] =
      quote do
        {:ok, value} ->
          (fn unquote(lhs) ->
             unquote(acc)
           end).(value)
          |> Reather.run(env)

        {:error, _} = error ->
          error
      end

    [ok | (else_body || []) ++ err]
  end

  defp parse_exprs(exprs, else_body) do
    [ret | body] = exprs |> Enum.reverse()

    wrapped_ret =
      quote do
        Reather.new(fn _ -> Reather.Either.new(unquote(ret)) end)
      end

    body
    |> List.foldl(wrapped_ret, fn
      {:<-, _ctx, [lhs, rhs]}, acc ->
        match = build_match(lhs, acc, else_body)

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

      {:=, _ctx, [lhs, rhs]}, acc ->
        quote do
          unquote(rhs)
          |> (fn unquote(lhs) ->
                unquote(acc)
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
