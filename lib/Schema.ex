defmodule SoftBank.Schema do
  @moduledoc false
  defmacro __using__(_options) do
    type = SoftBank.Config.key_type()

    case type do
      :binary_id ->
        quote do
          use Ecto.Schema
          @primary_key {:id, :binary_id, autogenerate: true}
          @foreign_key_type :binary_id
        end

      _ ->
        quote do
          use Ecto.Schema
          @primary_key {:id, :id, autogenerate: true}
          @foreign_key_type :id
        end
    end
  end
end
