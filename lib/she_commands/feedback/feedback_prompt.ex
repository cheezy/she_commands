defmodule SheCommands.Feedback.FeedbackPrompt do
  @moduledoc """
  Schema for tracking the lifecycle of a single feedback prompt.

  A prompt is scheduled for a future point in a plan (mid-plan or
  post-plan), delivered to the member, and (optionally) responded to.
  Status moves through: pending -> sent -> responded (or expired if the
  member never replies in time).
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias SheCommands.Accounts.User
  alias SheCommands.Plans.Plan

  @prompt_types [:mid_plan, :post_plan]
  @statuses [:pending, :sent, :responded, :expired]

  def prompt_types, do: @prompt_types
  def statuses, do: @statuses

  schema "feedback_prompts" do
    belongs_to :plan, Plan
    belongs_to :user, User

    field :prompt_type, Ecto.Enum, values: @prompt_types
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :scheduled_for, :utc_datetime
    field :sent_at, :utc_datetime
    field :responded_at, :utc_datetime
    field :response, :string

    timestamps(type: :utc_datetime)
  end

  @create_required [:plan_id, :user_id, :prompt_type]
  @create_optional [:status, :scheduled_for]

  def create_changeset(prompt, attrs) do
    prompt
    |> cast(attrs, @create_required ++ @create_optional)
    |> validate_required(@create_required)
    |> foreign_key_constraint(:plan_id)
    |> foreign_key_constraint(:user_id)
  end

  def mark_sent_changeset(prompt) do
    prompt
    |> change()
    |> put_change(:status, :sent)
    |> put_change(:sent_at, now())
  end

  def mark_responded_changeset(prompt, response) do
    prompt
    |> cast(%{response: response}, [:response])
    |> validate_required([:response])
    |> put_change(:status, :responded)
    |> put_change(:responded_at, now())
  end

  def mark_expired_changeset(prompt) do
    prompt
    |> change()
    |> put_change(:status, :expired)
  end

  defp now, do: DateTime.truncate(DateTime.utc_now(), :second)
end
