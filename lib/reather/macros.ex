defmodule Reather.Macros do
  defmacro reather(head, do: body) do
    built_body = build_body(body)

    quote do
      def unquote(head) do
        unquote(built_body)
      end
    end
  end

  defmacro reatherp(head, do: body) do
    built_body = build_body(body)

    quote do
      defp unquote(head) do
        unquote(built_body)
      end
    end
  end

  def build_body({:__block__, _ctx, exprs}) do
    parse_exprs(exprs)
  end

  def build_body(expr) do
    parse_exprs([expr])
  end

  def parse_exprs(exprs) do
    [ret | body] = exprs |> Enum.reverse()

    wrapped_ret =
      quote do
        Reather.new(fn _ -> Reather.either(unquote(ret)) end)
      end

    body |> List.foldl(wrapped_ret, &parse_expr/2)
  end

  def parse_expr({:<-, _ctx, [lhs, rhs]}, acc) do
    quote do
      unquote(rhs)
      |> Reather.wrap()
      |> (fn %Reather{} = r ->
            fn env ->
              r
              |> Reather.run(env)
              |> case do
                %Reather.Left{} = left ->
                  left

                %Reather.Right{right: value} ->
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

  def parse_expr({:let, _ctx1, [{:=, _ctx2, [lhs, rhs]}]}, acc) do
    quote do
      unquote(rhs)
      |> (fn unquote(lhs) ->
            unquote(acc)
          end).()
    end
  end
end
