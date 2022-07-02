defmodule ReatherTest.ReatherpTest do
  use ExUnit.Case
  use Reather

  defmodule Target do
    use Reather

    reather foo(a, b) do
      x = a + b
      y <- bar(a)

      x + y
    end

    reatherp bar(a) do
      -a
    end
  end

  test "with public foo" do
    assert {:ok, 2} == Target.foo(1, 2) |> Reather.run()
  end

  test "failed to call private bar" do
    assert_raise UndefinedFunctionError, fn ->
      Code.eval_quoted(
        quote do
          alias!(Target).bar(1) |> Reather.run()
        end
      )
    end
  end
end
