defmodule Reather.Macros do
  @doc """
  Declare a reather.
  """
  defmacro reather(head, do: body) do
    built_body = build_body(body)

    quote do
      def unquote(head) do
        unquote(built_body)
      end
    end
  end

  defmacro reather(do: body) do
    build_body(body)
  end

  @doc """
  Declare a private reather.
  """
  defmacro reatherp(head, do: body) do
    built_body = build_body(body)

    quote do
      defp unquote(head) do
        unquote(built_body)
      end
    end
  end

  defp build_body({:__block__, _ctx, exprs}) do
    parse_exprs(exprs)
  end

  defp build_body(expr) do
    parse_exprs([expr])
  end

  defp parse_exprs(exprs) do
    [ret | body] = exprs |> Enum.reverse()

    wrapped_ret =
      quote do
        Reather.new(fn _ -> Reather.either(unquote(ret)) end)
      end

    body |> List.foldl(wrapped_ret, &parse_expr/2)
  end

  defp parse_expr({:<-, _ctx, [lhs, rhs]}, acc) do
    quote do
      unquote(rhs)
      |> Reather.wrap()
      |> (fn %Reather{} = r ->
            fn env ->
              r
              |> Reather.run(env)
              |> case do
                {:error, _} = error ->
                  error

                {:ok, value} ->
                  (fn unquote(lhs) ->
                     unquote(acc)
                   end).(value)
                  |> Reather.run(env)
              end
            end
            |> Reather.new()
          end).()
    end
  end

  defp parse_expr({:=, _ctx, [lhs, rhs]}, acc) do
    quote do
      unquote(rhs)
      |> (fn unquote(lhs) ->
            unquote(acc)
          end).()
    end
  end
end
