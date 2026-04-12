defmodule SheCommands.Plans.Plan do
  @moduledoc """
  Schema for execution plans.

  A plan is generated from an intake response and contains selected
  modules organized by Power Pillar, a goal statement, expected outcomes,
  and a weekly schedule.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias SheCommands.Accounts.User
  alias SheCommands.Intake.GoalCategory
  alias SheCommands.Intake.IntakeResponse
  alias SheCommands.Plans.PlanModule

  @plan_types [:weekly, :biweekly, :monthly]
  @statuses [:generating, :active, :completed, :archived]

  def plan_types, do: @plan_types
  def statuses, do: @statuses

  schema "plans" do
    belongs_to :user, User
    belongs_to :intake_response, IntakeResponse
    belongs_to :goal_category, GoalCategory

    field :plan_type, Ecto.Enum, values: @plan_types
    field :status, Ecto.Enum, values: @statuses, default: :generating
    field :goal_statement, :string
    field :expected_outcomes, :string
    field :schedule, :map, default: %{}

    has_many :plan_modules, PlanModule

    timestamps(type: :utc_datetime)
  end

  @required_fields [:user_id, :plan_type]
  @optional_fields [
    :intake_response_id,
    :goal_category_id,
    :status,
    :goal_statement,
    :expected_outcomes,
    :schedule
  ]

  def changeset(plan, attrs) do
    plan
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:intake_response_id)
    |> foreign_key_constraint(:goal_category_id)
  end
end
