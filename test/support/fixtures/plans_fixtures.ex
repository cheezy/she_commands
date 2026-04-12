defmodule SheCommands.PlansFixtures do
  @moduledoc """
  Test helpers for creating entities via the `SheCommands.Plans` context.
  """

  import SheCommands.AccountsFixtures
  import SheCommands.ModulesFixtures

  alias SheCommands.Plans

  def plan_fixture(attrs \\ %{}) do
    user = attrs[:user] || user_fixture()

    {:ok, plan} =
      attrs
      |> Enum.into(%{
        user_id: user.id,
        plan_type: :weekly,
        status: :active,
        goal_statement: "Test goal statement",
        expected_outcomes: "Test expected outcomes"
      })
      |> Plans.create_plan()

    plan
  end

  def plan_module_fixture(plan, attrs \\ %{}) do
    module = attrs[:module] || module_fixture()

    {:ok, plan_module} =
      attrs
      |> Enum.into(%{
        plan_id: plan.id,
        module_id: module.id,
        power_pillar: :power_up,
        position: System.unique_integer([:positive])
      })
      |> Plans.add_plan_module()

    plan_module
  end
end
