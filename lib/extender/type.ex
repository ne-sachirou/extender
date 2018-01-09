defmodule ExTendEr.Type do
  @moduledoc """
  """

  alias ExTendEr.Library

  @type basic_type :: atom

  @type t ::
    basic_type |
    {:of, t, t} |
    {:or, [t]}

  @spec of(t, t) :: t
  def of(container_type, content_type), do: {:of, container_type, content_type}

  @spec union([t]) :: t
  def union(types), do: {:or, types}

  @spec subtype?(t, t, Library.typedefs) :: boolean
  def subtype?(type, super_type, typedefs) when is_atom(type) and is_atom(super_type) do
    type = resolve_alias type, typedefs
    super_type = resolve_alias super_type, typedefs
    if is_atom(type) and is_atom(super_type) do
      type == super_type or
        not root_type?(type, typedefs) and
        subtype?(typedefs[type][:super], super_type, typedefs)
    else
      subtype? type, super_type, typedefs
    end
  end
  def subtype?({:of, container_type, content_type}, super_type, typedefs) do
    case resolve_alias super_type, typedefs do
      {:of, super_container_type, super_content_type} ->
        subtype?(container_type, super_container_type, typedefs) and
          subtype?(content_type, super_content_type, typedefs)
      _ -> false
    end
  end
  def subtype?({:or, types}, super_type, typedefs), do: Enum.all? types, &subtype?(&1, super_type, typedefs)
  def subtype?(type, {:or, super_types}, typedefs), do: Enum.any? super_types, &subtype?(type, &1, typedefs)

  @spec root_type?(t, Library.typedefs) :: boolean
  defp root_type?(type, typedefs), do: is_nil typedefs[type][:super]

  @spec resolve_alias(t, Library.typedefs) :: t
  defp resolve_alias(type, typedefs) when is_atom type do
    case typedefs[type][:alias] do
      nil -> type
      type when is_atom(type) -> resolve_alias type, typedefs
      type -> type
    end
  end
  defp resolve_alias(type, _), do: type
end
