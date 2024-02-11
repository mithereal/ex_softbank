if Code.ensure_loaded?(Phoenix.HTML.Safe) do
  defimpl Phoenix.HTML.Safe, for: SoftBank.Note do
    def to_iodata(note), do: Phoenix.HTML.Safe.to_iodata(to_string(note))
  end
end
