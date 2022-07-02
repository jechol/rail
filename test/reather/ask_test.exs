defmodule ReatherTest.AskTest do
  use ExUnit.Case
  use Reather

  defmodule Target do
    use Reather

    reather single() do
      1 + 1
    end

    reather multi() do
      %{a: a} <- Reather.ask()
      %{b: b} <- Reather.ask()
      1 + a + b
    end
  end

  test "single" do
    assert {:ok, 2} == Target.single() |> Reather.run(%{})
  end

  test "multi" do
    assert {:ok, 111} == Target.multi() |> Reather.run(%{a: 10, b: 100})
  end
end
