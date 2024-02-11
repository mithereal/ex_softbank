compiled =
  case Code.ensure_compiled(Phoenix.HTML.Safe) do
    {:module, _} -> true
    _ -> false
  end

if compiled == true do
  defimpl Phoenix.HTML.Safe, for: SoftBank.Note do
    def to_iodata(note), do: Phoenix.HTML.Safe.to_iodata(to_string(note))
  end
end
