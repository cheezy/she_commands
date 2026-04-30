defmodule SheCommands.Feedback.FeedbackSurvey do
  @moduledoc """
  Schema for a structured feedback survey tied to a plan.

  Two survey types are supported: a mid-plan check-in (~halfway through
  the plan) and a post-plan review (after completion). Responses are
  stored as a free-form map so the survey questions can evolve without a
  schema migration.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias SheCommands.Accounts.User
  alias SheCommands.Plans.Plan

  @survey_types [:mid_plan_check, :post_plan_review]

  def survey_types, do: @survey_types

  schema "feedback_surveys" do
    belongs_to :plan, Plan
    belongs_to :user, User

    field :survey_type, Ecto.Enum, values: @survey_types
    field :responses, :map, default: %{}
    field :completed_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @create_required [:plan_id, :user_id, :survey_type]
  @create_optional [:responses, :completed_at]

  def create_changeset(survey, attrs) do
    survey
    |> cast(attrs, @create_required ++ @create_optional)
    |> validate_required(@create_required)
    |> foreign_key_constraint(:plan_id)
    |> foreign_key_constraint(:user_id)
  end

  def complete_changeset(survey, responses) when is_map(responses) do
    survey
    |> cast(%{responses: responses}, [:responses])
    |> put_change(:completed_at, DateTime.truncate(DateTime.utc_now(), :second))
  end
end
