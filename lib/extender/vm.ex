defmodule ExTendEr.VM do
  @moduledoc """
  """

  @type world :: term

  @type t :: %__MODULE__{
  }

  defstruct commands: []

  @spec next_step(t, world) :: {any, t}
  def next_step(vm, world) do
  end
end
