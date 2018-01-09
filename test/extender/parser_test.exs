defmodule ExTendEr.ParserTest do
  alias ExTendEr.Parser
  alias ExTendEr.TestSupport

  require TestSupport

  use ExTendEr.Properties
  use ExUnit.Case, async: true

  describe "sentences" do
    TestSupport.test_parse [
      {"", []},
      {" \n ", []},
      {" \n X\nY \n ", [{:val, "X"}, {:val, "Y"}]},
    ]
  end

  for op <- ~w(| & = < > <= >= + - * /)a do
    @tag op: op
    test to_string(op), %{op: op},
      do: assert [{op, {:val, "x"}, {:val, "y"}}] === Parser.parse! "x #{op} y"
  end

  test "!", do: assert [{:!, {:val, "x"}}] === Parser.parse! "! x"

   # describe "Parse if" do
   #   TestSupport.test_parse [
   #     {
   #       """
   #       IF X
   #         X1
   #         X2
   #       ELSEIF Y
   #         Y1
   #         Y2
   #       END
   #       """,
   #     },
   #   ]
   # end

  describe "Parse apply" do
    TestSupport.test_parse [
      {"X Y", [{:apply, {:val, "X"}, {:val, "Y"}}]},
      {"$X $Y", [{:apply, {:var, "X"}, {:var, "Y"}}]},
      {"X(Y)", [{:apply, {:val, "X"}, {:val, "Y"}}]},
      {"X ( \n Y \n )", [{:apply, {:val, "X"}, {:val, "Y"}}]},
      {"( \n X Y \n )", [{:apply, {:val, "X"}, {:val, "Y"}}]},
      {"$X(Y,Z)", [{:apply, {:var, "X"}, {:tuple, [{:val, "Y"}, {:val, "Z"}]}}]},
      {"X Y Z", [{:apply, {:val, "X"}, {:apply, {:val, "Y"}, {:val, "Z"}}}]},
      {"X Y(Z)", [{:apply, {:val, "X"}, {:apply, {:val, "Y"}, {:val, "Z"}}}]},
      {"X(Y Z)", [{:apply, {:val, "X"}, {:apply, {:val, "Y"}, {:val, "Z"}}}]},
      {"X(Y(Z))", [{:apply, {:val, "X"}, {:apply, {:val, "Y"}, {:val, "Z"}}}]},
      {"(X(Y(Z)))", [{:apply, {:val, "X"}, {:apply, {:val, "Y"}, {:val, "Z"}}}]},
      {"(X(Y Z))", [{:apply, {:val, "X"}, {:apply, {:val, "Y"}, {:val, "Z"}}}]},
    ]
  end

  describe "Parse boolean" do
    TestSupport.test_parse [
      {"true", [true]},
      {"TRUE", [true]},
      {"false", [false]},
      {"FALSE", [false]},
    ]
  end

  describe "Parse integer" do
    TestSupport.test_parse [
      {"42", [42]},
      {"+42", [42]},
      {"-42", [-42]},
      {"+ \n 42", [42]},
      {"- \n 42", [-42]},
    ]

    property "Random integer" do
      check all v <- integer() do
        assert [v] === Parser.parse! to_string(v)
      end
    end

    property "Integer form" do
      check all {sign, int} <- {sign(), positive_integer()} do
        expression = "#{sign}#{int}"
        {int, ""} = Integer.parse expression
        assert [int] === Parser.parse! expression
      end
    end
  end

  describe "Parse float" do
    property "Random float" do
      check all v <- float() do
        assert [v] === Parser.parse! to_string(v)
      end
    end

    # 42.57E-3
    property "Full float form" do
      check all {sign, int, fraction, exponent} <-
                {sign(), positive_integer(), fraction(), one_of([constant(""), exponent()])} do
        expression = "#{sign}#{int}#{fraction}#{exponent}"
        {float, ""} = Float.parse expression
        assert [float] === Parser.parse! expression
      end
    end

    # .57E-3
    property "Skip integer form" do
      check all {sign, int, fraction, exponent} <-
                {sign(), constant(""), fraction(), one_of([constant(""), exponent()])} do
        expression = "#{sign}#{int}#{fraction}#{exponent}"
        {float, ""} = Float.parse "#{sign}0#{fraction}#{exponent}"
        assert [float] === Parser.parse! expression
      end
    end

    # 42.E-3
    property "Skip fraction form" do
      check all {sign, int, fraction, exponent} <-
                {sign(), positive_integer(), constant(""), exponent()} do
        expression = "#{sign}#{int}.#{fraction}#{exponent}"
        {float, ""} = Float.parse "#{sign}#{int}.0#{exponent}"
        assert [float] === Parser.parse! expression
      end
    end

    # 42E-3
    property "No fraction form" do
      check all {sign, int, fraction, exponent} <-
                {sign(), positive_integer(), constant(""), exponent()} do
        expression = "#{sign}#{int}#{fraction}#{exponent}"
        {float, ""} = Float.parse "#{sign}#{int}#{exponent}"
        assert [float] === Parser.parse! expression
      end
    end
  end

  describe "Parse string" do
    for string <- [
          ~s(a),
          ~s(\\),
          ~s("),
          ~s(\#{),
        ] do
      @tag string: string
      test inspect(string), %{string: string} do
        assert [string] == Parser.parse! inspect string
      end
    end

    property "Random ascii string" do
      check all string <- string(:ascii) do
        assert [string] === Parser.parse! inspect string
      end
    end

    property "Random alphanumeric string" do
      check all string <- string(:alphanumeric) do
        assert [string] === Parser.parse! inspect string
      end
    end

    # property "Random printable string" do
    #   check all string <- string(:printable) do
    #     assert [string] === Parser.parse! inspect string
    #   end
    # end

    # property "Random CJK string" do
    #   check all string <- string([
    #     0x2E80..0x2EFF, # CJK Radicals Supplement
    #     0x3000..0x30FF, # CJK Symbols and Punctuation, Hiragana, Katakana
    #     0x3200..0x4DBF, # Enclosed CJK Letters and Months, CJK Compatibility, CJK Unified Ideographs Extension A
    #     0x4E00..0x9FFF, # CJK Unified Ideographs
    #     0xF900..0xFAFF, # CJK Compatibility Ideographs
    #     0xFE30..0xFE4F, # CJK Compatibility Forms
    #     0x20000..0x2FA1F, # CJK Unified Ideographs Extension B, CJK Compatibility Ideographs
    #   ]) do
    #     assert [string] === Parser.parse! inspect string
    #   end
    # end
  end

  describe "Parse val" do
    property "Random val" do
      check all name <- name() do
        assert [{:val, name}] === Parser.parse! name
      end
    end
  end

  describe "Parse var" do
    property "Random var" do
      check all name <- name() do
        assert [{:var, name}] === Parser.parse! "$" <> name
      end
    end
  end

  describe "Parse tuple" do
    TestSupport.test_parse [
      {"()", [{:tuple, []}]},
      {"(x)", [{:val, "x"}]},
      {"(x,)", [{:val, "x"}]},
      {"(x,y)", [{:tuple, [{:val, "x"}, {:val, "y"}]}]},
      {"(x,y,)", [{:tuple, [{:val, "x"}, {:val, "y"}]}]},
      {"( \n )", [{:tuple, []}]},
      {"( \n x \n )", [{:val, "x"}]},
      {"( \n x \n , \n )", [{:val, "x"}]},
      {"( \n x \n , \n y \n )", [{:tuple, [{:val, "x"}, {:val, "y"}]}]},
      {"( \n x \n , \n y \n , \n )", [{:tuple, [{:val, "x"}, {:val, "y"}]}]},
    ]
  end

  describe "Parse list" do
    TestSupport.test_parse [
      {"[]", [{:list, []}]},
      {"[x]", [{:list, [{:val, "x"}]}]},
      {"[x,]", [{:list, [{:val, "x"}]}]},
      {"[x,y]", [{:list, [{:val, "x"}, {:val, "y"}]}]},
      {"[x,y,]", [{:list, [{:val, "x"}, {:val, "y"}]}]},
      {"[ \n ]", [{:list, []}]},
      {"[ \n x \n ]", [{:list, [{:val, "x"}]}]},
      {"[ \n x \n , \n ]", [{:list, [{:val, "x"}]}]},
      {"[ \n x \n , \n y \n ]", [{:list, [{:val, "x"}, {:val, "y"}]}]},
      {"[ \n x \n , \n y \n , \n ]", [{:list, [{:val, "x"}, {:val, "y"}]}]},
    ]
  end
end
