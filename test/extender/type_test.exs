defmodule ExTendEr.TypeTest do
  alias ExTendEr.Type, as: T

  use ExUnit.Case, async: true

  describe "of/2" do
    test "of", do: {:of, :list, :int} = T.of :list, :int
  end

  describe "union/2" do
    test "union", do: {:or, [:int, :string]} = T.union [:int, :string]
  end

  describe "subtype?/3" do
    for {type, super_type, typedefs} <- [
          {:x, :x, %{x: []}},
          {:x, :y, %{x: [super: :y], y: []}},
          {:x, :y, %{x: [alias: :y], y: []}},
          {:x, :y, %{x: [alias: :y], y: [super: :z], z: []}},
          {:x, :y, %{x: [super: :z], y: [alias: :z], z: []}},
          {T.of(:list, :x), T.of(:list, :x), %{list: [], x: []}},
          {T.of(:list, :x), T.of(:list, :y), %{list: [], x: [super: :y], y: []}},
          {T.of(:list, :x), T.of(:array, :x), %{list: [super: :array], array: [], x: []}},
          {:x, T.union([:x]), %{x: []}},
          {:x, T.union([:y]), %{x: [super: :y], y: []}},
          {T.union([:x]), T.union([:x]), %{x: []}},
          {T.union([:x]), T.union([:y]), %{x: [super: :y], y: []}},
          {T.union([:x, :y]), T.union([:x, :y, :z]), %{x: [], y: [], z: []}},
          {:int, :id, %{id: [alias: T.union([:int, :string])], int: [], string: []}},
          {:string, :id, %{id: [alias: T.union([:int, :string])], int: [], string: []}},
        ] do
      @tag t: type, s: super_type, typedefs: typedefs
      test "#{inspect type} <: #{inspect super_type} @ #{inspect typedefs}",
        %{t: type, s: super_type, typedefs: typedefs},
        do: assert T.subtype? type, super_type, typedefs
    end

    for {type, super_type, typedefs} <- [
          {:x, :y, %{x: [], y: []}},
          {:x, :y, %{x: [super: :z], y: [], z: []}},
          {:x, :y, %{x: [alias: :z], y: [], z: []}},
          {T.of(:list, :x), T.of(:list, :y), %{list: [], x: [], y: []}},
          {T.of(:list, :x), T.of(:array, :x), %{list: [], array: [], x: []}},
          {:x, T.union([:y]), %{x: [], y: []}},
          {T.union([:x]), T.union([:y]), %{x: [], y: []}},
          {T.union([:x, :y]), T.union([:x, :z]), %{x: [], y: [], z: []}},
          {:float, :id, %{id: [alias: T.union([:int, :string])], int: [], string: [], float: []}},
        ] do
      @tag t: type, s: super_type, typedefs: typedefs
      test "not #{inspect type} <: #{inspect super_type} @ #{inspect typedefs}",
        %{t: type, s: super_type, typedefs: typedefs},
        do: refute T.subtype? type, super_type, typedefs
    end
  end
end
