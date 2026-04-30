defmodule SheCommands.Escalations.Escalation do
  @moduledoc """
  Schema for coach escalations.

  An escalation captures a request from a member to be seen by a coach,
  optionally tied to a specific plan or chat message. Status moves
  through pending -> in_review -> responded -> closed.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias SheCommands.Accounts.User
  alias SheCommands.Chat.ChatMessage
  alias SheCommands.Plans.Plan

  @statuses [:pending, :in_review, :responded, :closed]
  @subjects [:plan_clarification, :motivation_support, :event_prioritization]

  def statuses, do: @statuses
  def subjects, do: @subjects

  schema "escalations" do
    belongs_to :user, User
    belongs_to :plan, Plan
    belongs_to :chat_message, ChatMessage
    belongs_to :coach, User, foreign_key: :coach_id

    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :subject, Ecto.Enum, values: @subjects
    field :user_note, :string
    field :coach_response, :string
    field :responded_at, :utc_datetime
    field :sla_deadline, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @create_required [:user_id, :subject, :sla_deadline]
  @create_optional [:plan_id, :chat_message_id, :user_note, :status]

  def create_changeset(escalation, attrs) do
    escalation
    |> cast(attrs, @create_required ++ @create_optional)
    |> validate_required(@create_required)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:plan_id)
    |> foreign_key_constraint(:chat_message_id)
  end

  def assign_coach_changeset(escalation, attrs) do
    escalation
    |> cast(attrs, [:coach_id])
    |> validate_required([:coach_id])
    |> put_change(:status, :in_review)
    |> foreign_key_constraint(:coach_id)
  end

  def respond_changeset(escalation, attrs) do
    escalation
    |> cast(attrs, [:coach_response])
    |> validate_required([:coach_response])
    |> put_change(:status, :responded)
    |> put_change(:responded_at, DateTime.truncate(DateTime.utc_now(), :second))
  end

  def close_changeset(escalation) do
    escalation
    |> change()
    |> put_change(:status, :closed)
  end
end
