defmodule SoftBank.Note.Sigils do
  alias SoftBank.Note

  defmacro sigil_N({:<<>>, _meta, [amount]}, []),
    do: Macro.escape(SoftBank.Note.new(amount))

  defmacro sigil_N({:<<>>, _meta, [amount]}, [_ | _] = currency),
    do: Macro.escape(SoftBank.Note.new(amount, List.to_atom(currency)))
end
