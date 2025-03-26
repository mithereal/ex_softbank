Mix.Task.run("ecto.drop", ["quiet", "-r", "SoftBank.Repo"])
Mix.Task.run("ecto.create", ["quiet", "-r", "SoftBank.Repo"])
Mix.Task.run("ecto.migrate", ["-r", "SoftBank.Repo"])

{:ok, _} = Application.ensure_all_started(:ex_machina)

SoftBank.TestRepo.start_link()
ExUnit.start(capture_log: true)

Ecto.Adapters.SQL.Sandbox.mode(SoftBank.TestRepo, :manual)
