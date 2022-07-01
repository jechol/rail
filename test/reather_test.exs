defmodule ReatherTest do
  use ExUnit.Case
  doctest Reather

  alias Reather.Right
  import ExUnit.CaptureIO

  defmodule Target do
    require Reather.Macros
    import Reather.Macros

    reather foo(a, b) do
      let x = a + b
      y <- bar(a)

      x + y
    end

    reather bar(a) do
      -a |> IO.inspect()
    end
  end

  test "Simple reather" do
    # IO.inspect will be run lazily.
    {%Reather{}, ""} =
      with_io(fn ->
        Target.bar(1)
      end)

    assert Target.foo(1, 2) |> Reather.run() == %Right{right: 2}
  end
end
