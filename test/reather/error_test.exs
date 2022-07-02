defmodule ReatherTest.ErrorTest do
  use ExUnit.Case
  use Reather

  defmodule Target do
    use Reather

    reather foo() do
      x <- {:ok, 1}
      y <- {:error, "asdf", 1}

      x + y
    end
  end

  test "returns error" do
    assert {:error, {"asdf", 1}} == Target.foo() |> Reather.run()
  end
end
