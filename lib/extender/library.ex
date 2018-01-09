defmodule ExTendEr.Library do
  @moduledoc """
  """

  alias ExTendEr.Type, as: T

  @type typedefs :: %{
    T.basic_type => [
      super: T.t,
      alias: T.t,
    ],
  }

  @type t :: %__MODULE__{
    name: String.t,
    typedefs: typedefs,
    defs: %{String.t => {[T.t], function} | [{[T.t], function}]},
  }

  defstruct [
    name: "",
    typedefs: %{},
    defs: %{},
  ]

  def validate(library) do
    validate_typedefs library.typedefs
  end

  defp validate_typedefs(_typedefs) do
  end
end
