defmodule RailTest do
  use ExUnit.Case
  use Rail

  doctest Rail

  defmodule Calc do
    use Rail

    rail div(num, denom) do
      denom <- check_denom(denom)
      num / denom
    end

    rail check_denom(0) do
      {:error, :div_by_zero}
    end

    rail check_denom(n) do
      # same with {:ok, n}
      n
    end
  end

  test "rail/2" do
    assert 5.0 == Calc.div(10, 2)
    assert {:error, :div_by_zero} == Calc.div(10, 0)
  end

  defmodule Calc2 do
    use Rail

    def div(num, denom) do
      denom <- check_denom(denom)
      num / denom
    end

    def check_denom(0) do
      {:error, :div_by_zero}
    end

    def check_denom(n) do
      # same with {:ok, n}
      n
    end
  end

  test "def/2" do
    assert 5.0 == Calc2.div(10, 2)
    assert {:error, :div_by_zero} == Calc2.div(10, 0)
  end

  test "rail/1" do
    result =
      rail do
        x <- {:ok, 1}
        y <- {:ok, 2}

        x + y
      end

    assert 3 == result
  end
end
