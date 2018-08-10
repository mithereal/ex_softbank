defmodule Bank.Note.Sigils do

  alias Bank.Note
  defmacro sigil_N({:<<>>, _meta, [amount]}, []),
    do: Macro.escape(Bank.Note.new(to_integer(amount)))
  defmacro sigil_N({:<<>>, _meta, [amount]}, [_ | _]=currency),
    do: Macro.escape(Bank.Note.new(to_integer(amount), List.to_atom(currency)))

  defp to_integer(string) do
    string
    |> String.replace("_", "")
    |> String.to_integer
  end
end
