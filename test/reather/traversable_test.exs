defmodule ReatherTest.TraversableTest do
  use ExUnit.Case
  alias Reather
  alias Reather.Either

  test "either list" do
    assert {:ok, []} == [] |> Either.traverse()
    assert {:ok, [1, 2, 3]} == [{:ok, 1}, {:ok, 2}, {:ok, 3}] |> Either.traverse()

    assert {:error, "error"} == [{:ok, 1}, {:error, "error"}, {:ok, 3}] |> Either.traverse()
  end

  test "reather list" do
    assert {:ok, []} == [] |> Reather.traverse() |> Reather.run()

    assert {:ok, [1, 2, 3]} ==
             [{:ok, 1}, {:ok, 2}, {:ok, 3}]
             |> Enum.map(&Reather.of/1)
             |> Reather.traverse()
             |> Reather.run()

    assert {:error, "error"} ==
             [{:ok, 1}, {:error, "error"}, {:ok, 3}]
             |> Enum.map(&Reather.of/1)
             |> Reather.traverse()
             |> Reather.run()
  end
end
