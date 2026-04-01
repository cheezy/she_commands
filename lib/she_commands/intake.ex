defmodule SheCommands.Intake do
  @moduledoc """
  The Intake context.

  Manages intake questionnaire responses and goal categories.
  """

  import Ecto.Query, warn: false
  alias SheCommands.Repo

  alias SheCommands.Intake.GoalCategory
  alias SheCommands.Intake.IntakeResponse

  ## Goal Categories

  @doc """
  Returns the list of all goal categories ordered by position.
  """
  def list_goal_categories do
    GoalCategory
    |> order_by(:position)
    |> Repo.all()
  end

  @doc """
  Gets a single goal category by id.
  """
  def get_goal_category(id), do: Repo.get(GoalCategory, id)

  @doc """
  Gets a single goal category by slug.
  """
  def get_goal_category_by_slug(slug) when is_binary(slug) do
    Repo.get_by(GoalCategory, slug: slug)
  end

  @doc """
  Creates a goal category.
  """
  def create_goal_category(attrs) do
    %GoalCategory{}
    |> GoalCategory.changeset(attrs)
    |> Repo.insert()
  end

  ## Intake Responses

  @doc """
  Creates a new intake response for the given user.
  """
  def create_intake_response(user) do
    %IntakeResponse{}
    |> IntakeResponse.create_changeset(%{user_id: user.id})
    |> Repo.insert()
  end

  @doc """
  Gets the active (in_progress) intake response for a user.
  Returns nil if there is no active intake.
  """
  def get_active_intake_response(user) do
    IntakeResponse
    |> where([r], r.user_id == ^user.id and r.status == :in_progress)
    |> order_by([r], desc: r.id)
    |> limit(1)
    |> Repo.one()
    |> Repo.preload(:goal_category)
  end

  @doc """
  Gets or creates an active intake response for a user.
  If one exists in_progress, returns it. Otherwise creates a new one.
  """
  def get_or_create_active_intake_response(user) do
    case get_active_intake_response(user) do
      nil -> create_intake_response(user)
      response -> {:ok, response}
    end
  end

  @doc """
  Gets an intake response by id, scoped to the given user.
  """
  def get_intake_response(user, id) do
    IntakeResponse
    |> where([r], r.user_id == ^user.id and r.id == ^id)
    |> Repo.one()
    |> Repo.preload(:goal_category)
  end

  @doc """
  Lists all intake responses for a user, newest first.
  """
  def list_intake_responses(user) do
    IntakeResponse
    |> where([r], r.user_id == ^user.id)
    |> order_by([r], desc: r.id)
    |> Repo.all()
    |> Repo.preload(:goal_category)
  end

  @doc """
  Updates the goal step fields of an intake response.
  """
  def update_intake_goal(intake_response, attrs) do
    intake_response
    |> IntakeResponse.goal_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the availability step fields of an intake response.
  """
  def update_intake_availability(intake_response, attrs) do
    intake_response
    |> IntakeResponse.availability_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the preferences step fields of an intake response.
  """
  def update_intake_preferences(intake_response, attrs) do
    intake_response
    |> IntakeResponse.preferences_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the regimen step fields of an intake response.
  """
  def update_intake_regimen(intake_response, attrs) do
    intake_response
    |> IntakeResponse.regimen_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the location step fields of an intake response.
  """
  def update_intake_location(intake_response, attrs) do
    intake_response
    |> IntakeResponse.location_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the current step of an intake response.
  """
  def update_intake_step(intake_response, step) when is_integer(step) do
    intake_response
    |> IntakeResponse.step_changeset(%{current_step: step})
    |> Repo.update()
  end

  @doc """
  Marks an intake response as completed.
  Validates that all required fields are present.
  """
  def complete_intake_response(intake_response) do
    intake_response
    |> IntakeResponse.completion_changeset(%{})
    |> Repo.update()
  end
end
