defmodule ReatherTest.ModuleTest do
  use ExUnit.Case
  use Reather
  import ExUnit.CaptureIO

  defmodule Target do
    use Reather

    reather foo(a, b) do
      x = a + b
      y <- bar(a)

      x + y
    end

    reather bar(a) do
      -a
    end

    reather baz(a), do: a + 1
  end

  test "Simple reather" do
    assert Target.foo(1, 2) |> Reather.run() == {:ok, 2}
  end

  test "inline reather" do
    r =
      reather do
        x <- Target.baz(1)
        y <- Target.baz(1) |> Reather.inspect()

        x + y
      end

    assert fn -> Reather.run(r) end
           |> with_io() ==
             {{:ok, 4}, "{:ok, 2}\n"}
  end
end
