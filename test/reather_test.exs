defmodule ReatherTest do
  use ExUnit.Case
  use Reather
  import ExUnit.CaptureIO

  doctest Reather

  defmodule Target do
    use Reather

    reather foo(a, b) do
      x = a + b
      y <- bar(a)

      x + y
    end

    reather bar(a) do
      -a |> IO.inspect()
    end

    reather baz(a), do: a + 1

    reather qux() do
      env <- Reather.ask()
      x <- quux() |> Reather.run(Map.put(env, :a, 1))
      y = env.b

      x + y
    end

    reather quux() do
      env <- Reather.ask()

      env.a
    end
  end

  test "Simple reather" do
    # IO.inspect will be run lazily.
    {%Reather{} = r, ""} =
      with_io(fn ->
        Target.bar(1)
      end)

    assert with_io(fn ->
             Reather.run(r)
           end) == {{:ok, -1}, "-1\n"}

    assert Target.foo(1, 2) |> Reather.run() == {:ok, 2}

    assert Target.baz(1) |> Reather.run() == {:ok, 2}
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

  test "use environment" do
    assert Target.qux() |> Reather.run(%{b: 1}) == {:ok, 2}
  end
end
