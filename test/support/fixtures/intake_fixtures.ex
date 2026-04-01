defmodule SheCommands.IntakeFixtures do
  @moduledoc """
  Test helpers for creating intake-related entities.
  """

  alias SheCommands.Intake
  alias SheCommands.Repo

  def goal_category_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Commanding Presence #{System.unique_integer([:positive])}",
        slug: "commanding-presence-#{System.unique_integer([:positive])}",
        description: "You build confidence, executive presence, and speak with authority."
      })

    {:ok, category} = Intake.create_goal_category(attrs)
    category
  end

  def intake_response_fixture(user, attrs \\ %{}) do
    {:ok, response} = Intake.create_intake_response(user)

    if map_size(attrs) > 0 do
      response
      |> Ecto.Changeset.change(attrs)
      |> Repo.update!()
    else
      response
    end
  end
end
