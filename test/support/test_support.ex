defmodule ExTendEr.TestSupport do
  defmacro test_parse(sets) do
    quote do
      for {expression, expected} <- unquote(sets) do
        @tag expression: expression, expected: expected
        test inspect(expression), %{expression: expression, expected: expected},
          do: assert expected == ExTendEr.Parser.parse! expression
      end
    end
  end
end
