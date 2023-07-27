defmodule SoftBank do
  @moduledoc """
  The Main Interface for the Application
  """

  alias SoftBank.Accountant.Supervisor, as: SUPERVISOR
  alias SoftBank.Accountant, as: ACCOUNTANT

  defdelegate transfer(amount, from_account_hash, to_account_hash), to: ACCOUNTANT

  defdelegate withdrawl(amount, from_account_hash), to: ACCOUNTANT

  defdelegate deposit(amount, to_account_hash), to: ACCOUNTANT

  defdelegate convert(amount, dest_currency), to: ACCOUNTANT

  defdelegate balance(account_hash), to: ACCOUNTANT

  @doc """
  Login to the account
  This will start a genserver to act as an accountant to abstract transactions.
  """
  def login(account_number) do
    SUPERVISOR.start_child(account_number)
  end

  def show(account_number) do
    ACCOUNTANT.show_state(account_number)
  end

  @doc """
  Create a new account
  """
  def create(name) do
    SoftBank.Account.new(name)
  end

  @doc """
  Add a currency to the db and load into the ledger system
  """
  def add_currency(params) do
    SoftBank.Currencies.new(params)
  end

  # cache the app_version during build time
  @version Mix.Project.config()[:version]
  @description Mix.Project.config()[:description]
  @source_url Mix.Project.config()[:source_url]

  def description, do: @description
  def version, do: @version
  def source_url, do: @source_url
end
