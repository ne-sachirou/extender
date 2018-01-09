defmodule ExTendEr.Compiler do
  @moduledoc """
  """

  def compile(ast, library) do
    compile_node ast, library
  end

  defp compile_node(ast, library) when is_list(ast) do
    sentences = for sentence <- ast, do: compile_node sentence, library
    {return_type, functions} = Enum.reduce sentences, {:any, []}, fn {type, fun}, {return_type, functions} ->
      {type, [fun | functions]}
    end
    fun = fn {vm, world} ->
      Enum.reduce functions, {nil, vm}, fn fun, {result, vm} -> fun.({vm, world}) end
    end
    {return_type, fun}
  end
  defp compile_node(ast, _library) when is_integer(ast), do: {[:int], fn _ -> ast end}
  defp compile_node(ast, _library) when is_float(ast), do: {[:float], fn _ -> ast end}
  defp compile_node(ast, _library) when is_binary(ast), do: {[:string], fn _ -> ast end}
  defp compile_node({op, lhs, rhs}, library) when op in ~w(| & = < > <= >= + - * /)a do
    {ltype, lhs} = compile_node lhs, library
    {rtype, rhs} = compile_node rhs, library
    # dispatch op, [ltype, rtype], library
  end
end
