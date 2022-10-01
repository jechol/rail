defmodule ReatherTest.AfterTest do
  use ExUnit.Case
  use Reather
  import ExUnit.CaptureIO

  defmodule Target do
    use Reather

    reather foo(a, b) do
      x <- bar(a, b)

      x
    else
      {:error, "same"} -> {:ok, 2 * a}
      other -> other
    after
      IO.puts("foo")
    end

    def bar(a, b) do
      if a == b do
        {:error, "same"}
      else
        a + b
      end
    end
  end

  test "Simple reather" do
    assert {{:ok, 3}, "foo\n"} ==
             fn -> Target.foo(1, 2) |> Reather.run() end
             |> with_io()
             |> IO.inspect()

    assert {{:ok, 4}, "foo\n"} ==
             fn ->
               Target.foo(2, 2) |> Reather.run()
             end
             |> with_io()
  end

  test "inline reather" do
    r = fn a, b ->
      reather do
        x <- Target.bar(a, b)

        x
      else
        {:error, "same"} -> {:ok, 2 * a}
        other -> other
      after
        IO.puts("inline")
      end
    end

    assert {{:ok, 3}, "inline\n"} ==
             fn ->
               r.(1, 2) |> Reather.run()
             end
             |> with_io()

    assert {{:ok, 4}, "inline\n"} ==
             fn ->
               r.(2, 2) |> Reather.run()
             end
             |> with_io()
  end
end
