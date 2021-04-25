Mix.Task.run("ecto.drop", ["quiet", "-r", "SoftBank.TestRepo"])
Mix.Task.run("ecto.create", ["quiet", "-r", "SoftBank.TestRepo"])
Mix.Task.run("ecto.migrate", ["-r", "SoftBank.TestRepo"])

{:ok, _} = Application.ensure_all_started(:ex_machina)

SoftBank.TestRepo.start_link()
ExUnit.start(capture_log: true)

Ecto.Adapters.SQL.Sandbox.mode(SoftBank.TestRepo, :manual)
