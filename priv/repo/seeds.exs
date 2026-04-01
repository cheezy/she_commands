# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SheCommands.Repo.insert!(%SheCommands.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Seed initial admin user
alias SheCommands.Accounts
alias SheCommands.Accounts.User
alias SheCommands.Repo

admin_email = "admin@shecommands.ca"

unless Repo.get_by(User, email: admin_email) do
  {:ok, user} =
    Accounts.register_user(%{
      name: "Myra Reisler",
      email: admin_email,
      password: "AdminPassword123!"
    })

  user
  |> User.role_changeset(%{role: :admin})
  |> Repo.update!()

  IO.puts("Admin user created: #{admin_email}")
else
  IO.puts("Admin user already exists: #{admin_email}")
end
