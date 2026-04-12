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

# Seed test member user
member_email = "member@shecommands.ca"

unless Repo.get_by(User, email: member_email) do
  {:ok, _user} =
    Accounts.register_user(%{
      name: "Test Member",
      email: member_email,
      password: "MemberPassword123!"
    })

  IO.puts("Member user created: #{member_email}")
else
  IO.puts("Member user already exists: #{member_email}")
end

# Seed test coach user
coach_email = "coach@shecommands.ca"

unless Repo.get_by(User, email: coach_email) do
  {:ok, user} =
    Accounts.register_user(%{
      name: "Test Coach",
      email: coach_email,
      password: "CoachPassword123!"
    })

  user
  |> User.role_changeset(%{role: :coach})
  |> Repo.update!()

  IO.puts("Coach user created: #{coach_email}")
else
  IO.puts("Coach user already exists: #{coach_email}")
end

# Seed goal categories and module library
Code.require_file("priv/repo/seeds/module_library.exs")
