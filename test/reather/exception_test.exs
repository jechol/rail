defmodule ReatherTest.ExceptionTest do
  use ExUnit.Case
  use Reather

  defmodule Target do
    use Reather

    reather div(a, b) do
      x <- div_inner(a, b)

      x
    rescue
      ArithmeticError -> {:error, :div_by_zero}
    end

    def div_inner(a, b) when is_number(a) and is_number(b) do
      if b == 0 do
        raise ArithmeticError
      else
        a / b
      end
    end
  end

  test "Simple reather" do
    assert {:ok, 3} == Target.div(9, 3) |> Reather.run()
    assert {:error, :div_by_zero} == Target.div(1, 0) |> Reather.run()
    # Unhandled exception
    assert_raise FunctionClauseError, fn -> Target.div(:ok, :error) |> Reather.run() end
  end

  test "inline reather" do
    r = fn a, b ->
      reather do
        x <- Target.div_inner(a, b)

        x
      rescue
        ArithmeticError -> {:error, :div_by_zero}
      end
    end

    assert {:ok, 3} == r.(9, 3) |> Reather.run()

    assert {:error, :div_by_zero} == r.(1, 0) |> Reather.run()
  end
end
