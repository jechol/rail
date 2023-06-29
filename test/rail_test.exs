defmodule RailTest do
  use ExUnit.Case
  use Rail

  setup do
    Process.put(:rail_error_reporter, fn error, trace ->
      send(self(), {error, trace})
    end)

    :ok
  end

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

    refute_receive 5.0
    assert_receive {{:error, :div_by_zero}, [{RailTest, _, _, _} | _]}
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

  describe ">>>/2" do
    test "function" do
      assert "1" == {:ok, 1} >>> fn v -> Integer.to_string(v) end
      assert "1" == {:ok, 1} >>> (&Integer.to_string/1)
      assert "1" == {:ok, 1} >>> (&to_string/1)

      assert "100" == {:ok, 1} >>> fn v -> v * 100 end >>> (&Integer.to_string/1)
      assert {:error, :nan} == {:error, :nan} >>> fn v -> v * 100 end >>> (&Integer.to_string/1)
    end

    test "call" do
      assert "1" == {:ok, 1} >>> (fn v -> Integer.to_string(v) end).()
      assert "1" == {:ok, 1} >>> (&Integer.to_string/1).()
      assert "1" == {:ok, 1} >>> Kernel.to_string()
      assert "1" == {:ok, 1} >>> to_string()
      assert "1" == {:ok, 1} >>> to_string

      assert "100" == {:ok, 1} >>> Kernel.*(100) >>> Integer.to_string()
      assert {:error, :nan} == {:error, :nan} >>> Kernel.*(100) >>> Integer.to_string()
    end
  end
end
