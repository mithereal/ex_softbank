defmodule SoftBank.Note.Sigils do

  alias SoftBank.Note
  defmacro sigil_N({:<<>>, _meta, [amount]}, []),
    do: Macro.escape(SoftBank.Note.new(to_integer(amount)))
  defmacro sigil_N({:<<>>, _meta, [amount]}, [_ | _]=currency),
    do: Macro.escape(SoftBank.Note.new(to_integer(amount), List.to_atom(currency)))

  defp to_integer(string) do
    string
    |> String.replace("_", "")
    |> String.to_integer
  end
end
