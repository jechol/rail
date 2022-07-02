defmodule ReatherTest.AskTest do
  use ExUnit.Case
  use Reather

  defmodule Target do
    use Reather

    reather foo() do
      %{a: a} <- Reather.ask()
      %{b: b} <- Reather.ask()
      1 + a + b
    end

    reather bar() do
      x <- foo()

      x + 1
    end
  end

  test "use env" do
    assert {:ok, 111} == Target.foo() |> Reather.run(%{a: 10, b: 100})
  end

  test "use env whthin reather" do
    assert {:ok, 112} == Target.bar() |> Reather.run(%{a: 10, b: 100})
  end
end
