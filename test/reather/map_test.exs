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

  test "reather map" do
    assert {:error, 1} ==
             Target.foo()
             |> Reather.map(fn x -> x + 1 end)
             |> Reather.run()

    assert {:ok, 4} ==
             Target.bar()
             |> Reather.map(fn x -> x + 1 end)
             |> Reather.run()
  end

  test "either map" do
    assert {:error, 1} ==
             Either.error(1) |> Either.map(fn x -> x + 1 end)

    assert {:ok, 2} ==
             Either.new(1) |> Either.map(fn x -> x + 1 end)
  end
end
