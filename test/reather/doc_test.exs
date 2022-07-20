defmodule ReatherTest.DocTest do
  defmodule Target do
    use Reather

    @doc """
    Test function
    """
    reather foo() do
      %{a: a} <- Reather.ask()
      %{b: b} <- Reather.ask()
      1 + a + b
    end

    @doc false
    reather bar() do
      x <- foo()

      x + 1
    end
  end
end
