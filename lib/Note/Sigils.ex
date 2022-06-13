defmodule SoftBank.Note.Sigils do
  alias SoftBank.Note

  defmacro sigil_N({:<<>>, _meta, [amount]}, []),
    do: Macro.escape(Note.new(amount))

  defmacro sigil_N({:<<>>, _meta, [amount]}, [_ | _] = currency),
    do: Macro.escape(Note.new(List.to_atom(currency), amount))
end
