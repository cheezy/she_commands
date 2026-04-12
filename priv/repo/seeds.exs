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

# Seed goal categories
alias SheCommands.Intake.GoalCategory

goal_categories = [
  %{
    name: "Commanding Presence",
    slug: "commanding-presence",
    description:
      "Build confidence, executive presence, and the ability to command any room you walk into.",
    outcome_power_up: "Fuel your body and mind for high-visibility moments",
    outcome_power_through: "Build physical and mental stamina for sustained performance",
    outcome_power_down: "Manage pre-event nerves and post-performance recovery",
    outcome_empower: "Develop your leadership voice and personal brand",
    position: 1
  },
  %{
    name: "Decision-Making & Taking Action",
    slug: "decision-making-action",
    description:
      "Sharpen your ability to make bold decisions quickly and execute without hesitation.",
    outcome_power_up: "Optimize cognitive performance and mental clarity",
    outcome_power_through: "Build resilience to push through decision fatigue",
    outcome_power_down: "Clear mental clutter and reduce analysis paralysis",
    outcome_empower: "Strengthen strategic thinking and execution habits",
    position: 2
  },
  %{
    name: "Stress & Anxiety",
    slug: "stress-anxiety",
    description:
      "Develop tools to manage stress, reduce anxiety, and stay calm under pressure.",
    outcome_power_up: "Nourish your nervous system for resilience",
    outcome_power_through: "Build physical outlets for stress release",
    outcome_power_down: "Master recovery protocols for calm and clarity",
    outcome_empower: "Reframe stress as a performance tool",
    position: 3
  },
  %{
    name: "Emotional Resilience",
    slug: "emotional-resilience",
    description:
      "Strengthen your ability to bounce back, adapt, and thrive through challenges.",
    outcome_power_up: "Fuel emotional stability through nutrition and habits",
    outcome_power_through: "Build mental toughness through progressive challenges",
    outcome_power_down: "Develop recovery rituals for emotional recharge",
    outcome_empower: "Cultivate a growth mindset and self-compassion practice",
    position: 4
  },
  %{
    name: "Physical Vitality",
    slug: "physical-vitality",
    description:
      "Elevate your energy, strength, and physical readiness for life's biggest moments.",
    outcome_power_up: "Optimize nutrition and supplementation for peak energy",
    outcome_power_through: "Build functional strength and cardiovascular endurance",
    outcome_power_down: "Prioritize sleep, mobility, and active recovery",
    outcome_empower: "Align physical goals with your broader life mission",
    position: 5
  }
]

for attrs <- goal_categories do
  unless Repo.get_by(GoalCategory, slug: attrs.slug) do
    %GoalCategory{}
    |> GoalCategory.changeset(attrs)
    |> Repo.insert!()

    IO.puts("Goal category created: #{attrs.name}")
  else
    IO.puts("Goal category already exists: #{attrs.name}")
  end
end
