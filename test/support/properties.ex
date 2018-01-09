defmodule ExTendEr.Properties do
  import StreamData

  def sign, do: member_of ["", "+", "-"]

  def fraction, do: map {positive_integer(), positive_integer()}, fn {l, r} -> ".#{l}#{r}" end

  def exponent,
    do: map {member_of(~w(e E)), sign(), positive_integer()}, fn {e, sign, int} -> "#{e}#{sign}#{int}" end

  def name do
    filter(
      map(
        {
          filter(string([?a..?z, ?A..?Z, ?_]), &("" != &1)),
          string([?a..?z, ?A..?Z, ?0..?9, ?_]),
        }, fn {l, r} -> l <> r end
      ),
      &(&1 not in ["true", "TRUE", "false", "FALSE"])
    )
  end

  defmacro __using__(_) do
    quote do
      use ExUnitProperties
      import ExTendEr.Properties
    end
  end
end
