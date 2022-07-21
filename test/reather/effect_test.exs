defmodule ReatherTest.EffectTest do
  use ExUnit.Case
  use Reather
  import ExUnit.CaptureIO

  defmodule Target do
    reather foo() do
      x <- {:ok, 1}
      IO.puts(x)

      x + 1
    end
  end

  test "with side effect" do
    assert {{:ok, 2}, "1\n"} ==
             fn -> Target.foo() |> Reather.run() end
             |> with_io()
  end
end
