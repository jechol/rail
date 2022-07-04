defmodule ReatherTest.MapTest do
  use ExUnit.Case
  use Reather

  defmodule Target do
    use Reather

    reather foo() do
      x <- {:ok, 1}
      y <- {:error, 1}

      x + y
    end

    reather bar() do
      x <- {:ok, 1}
      y <- {:ok, 2}

      x + y
    end
  end

  test "map test" do
    assert {:error, 1} ==
             Target.foo()
             |> Reather.map(fn x -> x + 1 end)
             |> Reather.run()

    assert {:ok, 4} ==
             Target.bar()
             |> Reather.map(fn x -> x + 1 end)
             |> Reather.run()
  end
end
