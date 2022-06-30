defmodule Reather.Macros do
  defmacro reather(head, do: body) do
    IO.inspect(head)
    IO.inspect(body)
    _built_body = build_body(body)

    # IO.inspect(
    #  {:fn, ctx,
    #   [
    #     {:->, ctx, [args, body]}
    #   ]}
    # )

    quote do
      def unquote(head) do
        # unquote(body)
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

    IO.inspect("return:")

    IO.inspect(
      quote do
        Reather.Macros.wrap_reather(unquote(ret))
      end
    )

    body
    |> Enum.map(&parse_expr/1)
  end

  def wrap_reather(%Reather{} = r), do: r
  def wrap_reather(value), do: Reather.of(value)

  def parse_expr({:<-, _ctx, [lhs, rhs]}) do
    IO.inspect("<-:")
    IO.inspect(lhs)
    IO.inspect(rhs)
  end

  def parse_expr({:let, _ctx1, [{:=, _ctx2, [lhs, rhs]}]}) do
    IO.inspect("let:")
    IO.inspect(lhs)
    IO.inspect(rhs)
  end
end
