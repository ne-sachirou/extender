defmodule ExTendEr.Parser do
  @moduledoc """
  """

  use Neotomex.ExGrammar

  @root true
  define :sentences, "sentence+ / <wsnl>" do
    nil -> []
    sentences -> sentences
  end

  define :sentence, "<wsnl> term <wsnl>", do: ([term] -> term)

  define :term, "term5"

  define :term5, "term4 (<wsnl> ('|' / '&') <wsnl> term4)*",
    do: (matched -> binary_operator_term matched)

  define :term4, "term3 (<wsnl> ('<=' / '>=' / '=' / '<' / '>') <wsnl> term3)*",
    do: (matched -> binary_operator_term matched)

  define :term3, "term2 (<wsnl> ('+' / '-') <wsnl> term2)*",
    do: (matched -> binary_operator_term matched)

  define :term2, "term1 (<wsnl> ('*' / '/') <wsnl> term1)*",
    do: (matched -> binary_operator_term matched)

  define :term1, "term0 / ('!' <wsnl> term0)" do
    ["!", term] -> {:!, term}
    term -> term
  end

  define :term0, "apply / tuple / list / true / false / float / int / string / val / var"

  # define :if_term, "(IF / if) sentence sentences (END / end)"

  define :apply, "(val / var) <ws*> term",
    do: ([fun, term] -> {:apply, fun, term})

  define :tuple, "tuple_with_contents / empty_tuple"
  define :tuple_with_contents, "<'('> <wsnl> term (<wsnl> <','> <wsnl> term)* <wsnl> <','?> <wsnl> <')'>" do
    [head_term, []] -> head_term
    [head_term, [tail_terms]] -> {:tuple, [head_term | tail_terms]}
  end
  define :empty_tuple, "'(' wsnl ')'", do: (_ -> {:tuple, []})

  define :list, "list_with_contents / empty_list"
  define :list_with_contents, "<'['> <wsnl> term (<wsnl> <','> <wsnl> term)* <wsnl> <','?> <wsnl> <']'>" do
    [head_term, []] -> {:list, [head_term]}
    [head_term, [tail_terms]] -> {:list, [head_term | tail_terms]}
  end
  define :empty_list, "'[' wsnl ']'", do: (_ -> {:list, []})

  define :true, "'TRUE' / 'true'", do: (_ -> true)

  define :false, "'FALSE' / 'false'", do: (_ -> false)

  define :float, "float_body exponent? / int_expression '.' exponent? / int_expression exponent" do
    [{:int, int}, exponent] ->
      {float, ""} = Float.parse "#{int}#{exponent}"
      float
    [float_body, exponent] ->
      {float, ""} = Float.parse "#{float_body}#{exponent}"
      float
    [{:int, int}, ".", exponent] ->
      {float, ""} = Float.parse "#{int}.0#{exponent}"
      float
  end
  define :float_body, "int_expression fraction / sign <wsnl> fraction" do
    [{:int, int}, fraction] -> "#{int}#{fraction}"
    [sign, fraction] -> sign <> "0" <> fraction
  end
  define :fraction, "'.' [0-9]+", do: (["." | digits] -> Enum.join ["." | digits])
  define :exponent, "[eE] int_expression", do: ([_, {:int, int}] -> "E#{int}")

  define :int, "int_expression" do
    {:int, int_expression} ->
      {int, ""} = Integer.parse int_expression
      int
  end

  define :int_expression, "sign <wsnl> ([1-9] [0-9]* / '0')" do
    [sign, "0"] -> {:int, sign <> "0"}
    [sign, [head_digit, tail_digits]] -> {:int, Enum.join([sign, head_digit | tail_digits])}
  end

  define :sign, "('+' / '-')?", do: (sign -> sign || "+")

  define :string, "<'\"'> (<!'\"'> (backslash backslash / backslash doublequote / .))* <'\"'>" do
    [chars] ->
      for [char] <- chars, into: "" do
        case char do
          ["\\", "\\"] -> "\\"
          ["\\", "\""] -> "\""
          char -> char
        end
      end
  end
  define :backslash, "'\\\\'"
  define :doublequote, "'\"'"

  define :val, "name", do: (name -> {:val, name})

  define :var, "'$' name", do: (["$", name] -> {:var, name})

  define :name, "[_A-Za-z] [_A-Za-z0-9]*",
    do: ([head_char, tail_chars] -> Enum.join [head_char | tail_chars])

  define :ws, "[ \\t]", do: (_ -> :ws)

  define :nl, "'\\r\\n' / [\\r\\n]", do: (_ -> :nl)

  define :wsnl, "(ws / nl)*"

  _ = ~w(| & = < > <= >= + - * /)a
  defp binary_operator_term([head_term, tail_parts]),
    do: Enum.reduce tail_parts, head_term, fn [op, rhs], lhs -> {String.to_existing_atom(op), lhs, rhs} end
end
