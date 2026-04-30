defmodule SheCommands.EscalationsFixtures do
  @moduledoc """
  Test helpers for creating escalations.
  """

  import SheCommands.AccountsFixtures, only: [user_fixture: 1]

  alias SheCommands.Accounts.Scope
  alias SheCommands.Escalations

  def escalation_fixture(attrs \\ %{}) do
    {user, attrs} = Map.pop_lazy(attrs, :user, fn -> user_fixture(%{}) end)

    attrs =
      Enum.into(attrs, %{
        subject: :plan_clarification,
        user_note: "I need help understanding the plan."
      })

    scope = Scope.for_user(user)

    {:ok, escalation} = Escalations.create_escalation(scope, attrs)
    escalation
  end
end
