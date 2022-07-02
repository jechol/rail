defmodule ReatherTest.TupleTest do
  use ExUnit.Case
  use Reather

  defmodule Target do
    reather foo() do
      a <- {:ok, 1}
      {b, c} <- {:ok, 2, 3}
      d = nil
      ^d <- :ok

      a + b + c
    end
  end

  test "test tuple" do
    assert {:ok, 6} == Target.foo() |> Reather.run()
  end
end
