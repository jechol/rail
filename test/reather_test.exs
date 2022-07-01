defmodule ReatherTest do
  use ExUnit.Case
  use Reather
  import ExUnit.CaptureIO

  doctest Reather

  defmodule Target do
    use Reather

    reather foo(a, b) do
      let x = a + b
      y <- bar(a)

      x + y
    end

    reather bar(a) do
      -a |> IO.inspect()
    end

    reather baz(a), do: a + 1
  end

  test "Simple reather" do
    # IO.inspect will be run lazily.
    {%Reather{} = r, ""} =
      with_io(fn ->
        Target.bar(1)
      end)

    assert with_io(fn ->
             Reather.run(r)
           end) == {%Right{right: -1}, "-1\n"}

    assert Target.foo(1, 2) |> Reather.run() == %Right{right: 2}

    assert Target.baz(1) |> Reather.run() == %Right{right: 2}
  end

  test "inline reather" do
    r =
      reather do
        x <- Target.bar(1)
        y <- Target.baz(1)

        x + y
      end

    assert Reather.run(r) == %Right{right: 1}
  end
end
