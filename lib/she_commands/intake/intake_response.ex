defmodule SheCommands.Intake.IntakeResponse do
  @moduledoc """
  Schema for intake questionnaire responses.

  Each user can have multiple intake responses (for plan renewal/restart),
  but only one can be in_progress at a time. Supports partial saves so users
  can resume the multi-step flow.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias SheCommands.Accounts.User
  alias SheCommands.Intake.GoalCategory

  @statuses [:in_progress, :completed]
  @lead_times [:short, :medium, :long]
  @hours_per_day [:under_30, :thirty_to_sixty, :over_sixty]
  @intensities [:low, :moderate, :high]
  @coaching_preferences [:self_directed, :coach_guided]
  @fitness_regimens [:none, :light, :moderate, :active]
  @personal_dev_regimens [:none, :some, :active]

  schema "intake_responses" do
    belongs_to :user, User
    belongs_to :goal_category, GoalCategory

    field :status, Ecto.Enum, values: @statuses, default: :in_progress

    # Goal fields
    field :goal_intent, :string
    field :lead_time, Ecto.Enum, values: @lead_times

    # Availability fields
    field :days_per_week, :integer
    field :hours_per_day, Ecto.Enum, values: @hours_per_day
    field :intensity, Ecto.Enum, values: @intensities

    # Preferences
    field :limitations, {:array, :string}, default: []
    field :limitations_notes, :string
    field :coaching_preference, Ecto.Enum, values: @coaching_preferences

    # Current regimen
    field :fitness_regimen, Ecto.Enum, values: @fitness_regimens
    field :fitness_regimen_notes, :string
    field :personal_dev_regimen, Ecto.Enum, values: @personal_dev_regimens
    field :personal_dev_regimen_notes, :string

    # Location
    field :city, :string
    field :province, :string
    field :country, :string

    # Feedback
    field :feedback_interest, :boolean, default: false

    # Progress tracking
    field :current_step, :integer, default: 1
    field :completed_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns the list of valid statuses.
  """
  def statuses, do: @statuses

  @doc """
  Returns the list of valid lead times.
  """
  def lead_times, do: @lead_times

  @doc """
  Returns the list of valid hours per day options.
  """
  def hours_per_day_options, do: @hours_per_day

  @doc """
  Returns the list of valid intensities.
  """
  def intensities, do: @intensities

  @doc """
  Returns the list of valid coaching preferences.
  """
  def coaching_preferences, do: @coaching_preferences

  @doc """
  Changeset for creating a new intake response.
  Only requires user_id; all other fields are optional for partial saves.
  """
  def create_changeset(intake_response, attrs) do
    intake_response
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Changeset for updating goal-related fields (step 1-2).
  """
  def goal_changeset(intake_response, attrs) do
    intake_response
    |> cast(attrs, [:goal_intent, :goal_category_id])
    |> foreign_key_constraint(:goal_category_id)
  end

  @doc """
  Changeset for updating timeline and availability fields (step 3-5).
  """
  def availability_changeset(intake_response, attrs) do
    intake_response
    |> cast(attrs, [:lead_time, :days_per_week, :hours_per_day, :intensity])
    |> validate_number(:days_per_week, greater_than_or_equal_to: 1, less_than_or_equal_to: 7)
  end

  @doc """
  Changeset for updating preferences (step 6-7).
  """
  def preferences_changeset(intake_response, attrs) do
    intake_response
    |> cast(attrs, [:limitations, :limitations_notes, :coaching_preference])
  end

  @doc """
  Changeset for updating current regimen (step 8-9).
  """
  def regimen_changeset(intake_response, attrs) do
    intake_response
    |> cast(attrs, [
      :fitness_regimen,
      :fitness_regimen_notes,
      :personal_dev_regimen,
      :personal_dev_regimen_notes
    ])
  end

  @doc """
  Changeset for updating location and feedback (step 10-11).
  """
  def location_changeset(intake_response, attrs) do
    intake_response
    |> cast(attrs, [:city, :province, :country, :feedback_interest])
  end

  @doc """
  Changeset for updating the current step (progress tracking).
  """
  def step_changeset(intake_response, attrs) do
    intake_response
    |> cast(attrs, [:current_step])
    |> validate_number(:current_step, greater_than_or_equal_to: 1)
  end

  @doc """
  Changeset for marking the intake as completed.
  Validates that all required fields are present before completion.
  """
  def completion_changeset(intake_response, attrs) do
    intake_response
    |> cast(attrs, [:status, :completed_at])
    |> validate_required([
      :goal_intent,
      :goal_category_id,
      :lead_time,
      :days_per_week,
      :hours_per_day,
      :intensity
    ])
    |> put_change(:status, :completed)
    |> put_change(:completed_at, DateTime.truncate(DateTime.utc_now(), :second))
  end
end
