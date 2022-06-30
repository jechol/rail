defmodule ReatherTest do
  use ExUnit.Case
  doctest Reather

  alias Reather.Right

  defmodule Target do
    require Reather.Macros
    import Reather
    import Reather.Macros

    reather foo(a, b) do
      let x = a + b
      y <- bar(a)

      x + y
    end

    reather bar(a) do
      -a
    end
  end

  test "greets the world" do
    assert Target.foo(1, 2) |> Reather.run() == %Right{right: 2}
  end
end
