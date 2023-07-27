alias :observer, as: O
alias :debugger, as: D
alias SoftBank.{Owner, Account, AccountTest, TestRepo, Repo, Entry, EntryTest, Accountant, Amount, Currencies, Currency }


local_time = fn  ->
  {_date, {hour, minute, _second}} = :calendar.local_time()

      hour =
        case(hour > 12) do
          true -> hour - 12
          false -> hour
        end

      ds =
        [hour, minute]
        |> Enum.map(&String.pad_leading(Integer.to_string(&1), 2, "0"))
        |> Enum.join(":")

      case(hour > 12) do
        true -> ds <> "pm"
        false -> ds <> "am"
      end

      [hour, minute]
      |> Enum.map(&String.pad_leading(Integer.to_string(&1), 2, "0"))
      |> Enum.join(":")
  end

IEx.configure(
  colors: [
    syntax_colors: [
      number: :light_yellow,
      atom: :light_cyan,
      string: :light_black,
      boolean: :red,
      nil: [:magenta, :bright]
    ],
    ls_directory: :cyan,
    ls_device: :yellow,
    doc_code: :green,
    doc_inline_code: :magenta,
    doc_headings: [:cyan, :underline],
    doc_title: [:cyan, :bright, :underline]
  ],
  default_prompt:
    "[#{IO.ANSI.magenta()}#{local_time.()}#{IO.ANSI.reset()}]" <>
      "(#{IO.ANSI.green()}%prefix#{IO.ANSI.reset()} " <>
      ":: #{IO.ANSI.cyan()}%counter#{IO.ANSI.reset()})~",
  alive_prompt:
    "[#{IO.ANSI.magenta()}#{local_time.()}#{IO.ANSI.reset()} " <>
      "(#{IO.ANSI.green()}%prefix#{IO.ANSI.reset()} " <>
      "[#{IO.ANSI.yellow()}%node#{IO.ANSI.reset()}]) " <>
      ":: #{IO.ANSI.cyan()}%counter#{IO.ANSI.reset()}]~",
  history_size: 500,
  inspect: [
    pretty: true,
    limit: :infinity,
    width: 80
  ],
  width: 80
)

defmodule Debug do
  def load(name) do
    :i.ini(name)
  end

  def unload(name) do
    :int.nn(name)
  end

  def start() do
    D.start()
  end

  def stop() do
    D.stop()
  end

  def break(m, n, a) do
    :i.ini(m)
    :i.ib(m, n, a)
  end

  def break(m, n) do
    :i.ini(m)
    :i.ib(m, n)
  end

  def unbreak(m, n, a) do
    :i.ir(m, n, a)
  end

  def unbreak(m, n) do
    :i.ir(m, n)
  end

  def clear(m \\ nil) do
    :i.ir(m)
  end
end
