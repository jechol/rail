defmodule ReatherTest.ElseTest do
  use ExUnit.Case
  use Reather

  defmodule Target do
    use Reather

    reather foo1(a, b) do
      x <- bar(a, b)
      y <- baz(a)

      x + y
    else
      {:error, "zero"} -> {:ok, 2 * b}
      other -> other
    end

    reather foo2(a, b) do
      x <- foo1(a, b)

      x + 1
    end

    reather foo3(a, b) do
      x <- foo1(a, b)
      y <- baz(a)

      x + y
    else
      {:error, "same"} -> {:ok, a}
    end

    def bar(a, b) do
      if a == b do
        {:error, "same"}
      else
        a + b
      end
    end

    def baz(a) do
      if a == 0 do
        {:error, "zero"}
      else
        -a
      end
    end
  end

  test "Simple reather" do
    assert {:ok, 2} == Target.foo1(1, 2) |> Reather.run()
    assert {:ok, 4} == Target.foo1(0, 2) |> Reather.run()
    assert {:error, "same"} == Target.foo1(2, 2) |> Reather.run()

    assert {:ok, 3} == Target.foo2(1, 2) |> Reather.run()
    assert {:ok, 5} == Target.foo2(0, 2) |> Reather.run()
    assert {:error, "same"} == Target.foo2(2, 2) |> Reather.run()

    assert {:ok, 2} == Target.foo3(2, 2) |> Reather.run()
    assert_raise TryClauseError, fn -> Target.foo3(0, 2) |> Reather.run() end
  end

  test "inline reather" do
    r = fn a, b ->
      reather do
        x <- Target.bar(a, b)
        y <- Target.baz(a)

        x + y
      else
        {:error, "zero"} -> {:ok, 2 * b}
        other -> other
      end
    end

    assert {:ok, 2} == r.(1, 2) |> Reather.run()
    assert {:ok, 4} == r.(0, 2) |> Reather.run()
    assert {:error, "same"} == r.(2, 2) |> Reather.run()
  end
end
