defmodule Reather.ClauseError do
  @moduledoc """
  Raised when no else clause matches the result of a reather.
  """

  defexception [:message]

  @impl true
  def exception(value) do
    msg = "no reather's else clause matching: #{inspect(value)}"
    %__MODULE__{message: msg}
  end
end
