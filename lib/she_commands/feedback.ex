defmodule SheCommands.Feedback do
  @moduledoc """
  The Feedback context.

  Manages mid-plan prompts, post-plan surveys, their lifecycle, and the
  queries the feedback delivery workers and admin views need.
  """

  import Ecto.Query, warn: false

  alias SheCommands.Feedback.FeedbackPrompt
  alias SheCommands.Feedback.FeedbackSurvey
  alias SheCommands.Repo

  ## FeedbackPrompt

  @doc """
  Creates a feedback prompt.
  """
  def create_feedback_prompt(attrs) do
    %FeedbackPrompt{}
    |> FeedbackPrompt.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Fetches a feedback prompt by id (raises if not found).
  """
  def get_feedback_prompt!(id), do: Repo.get!(FeedbackPrompt, id)

  @doc """
  Lists feedback prompts attached to a plan, oldest scheduled first.
  """
  def list_prompts_for_plan(plan_id) do
    FeedbackPrompt
    |> where([p], p.plan_id == ^plan_id)
    |> order_by([p], asc: p.scheduled_for, asc: p.id)
    |> Repo.all()
  end

  @doc """
  Lists feedback prompts for a user, newest first.
  """
  def list_prompts_for_user(user_id) do
    FeedbackPrompt
    |> where([p], p.user_id == ^user_id)
    |> order_by([p], desc: p.inserted_at, desc: p.id)
    |> Repo.all()
  end

  @doc """
  Returns prompts in :pending state whose scheduled_for is in the past
  (or unset). Used by the feedback delivery worker.
  """
  def get_pending_prompts do
    now = DateTime.utc_now()

    FeedbackPrompt
    |> where([p], p.status == :pending)
    |> where([p], is_nil(p.scheduled_for) or p.scheduled_for <= ^now)
    |> order_by([p], asc: p.scheduled_for, asc: p.id)
    |> Repo.all()
  end

  @doc """
  Transitions a prompt from :pending to :sent and stamps sent_at.
  """
  def mark_prompt_sent(%FeedbackPrompt{} = prompt) do
    prompt
    |> FeedbackPrompt.mark_sent_changeset()
    |> Repo.update()
  end

  @doc """
  Records a response on a prompt and transitions it to :responded.
  """
  def mark_prompt_responded(%FeedbackPrompt{} = prompt, response) do
    prompt
    |> FeedbackPrompt.mark_responded_changeset(response)
    |> Repo.update()
  end

  @doc """
  Marks a prompt as expired (the member did not respond in time).
  """
  def mark_prompt_expired(%FeedbackPrompt{} = prompt) do
    prompt
    |> FeedbackPrompt.mark_expired_changeset()
    |> Repo.update()
  end

  ## FeedbackSurvey

  @doc """
  Creates a feedback survey.
  """
  def create_feedback_survey(attrs) do
    %FeedbackSurvey{}
    |> FeedbackSurvey.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Fetches a feedback survey by id (raises if not found).
  """
  def get_feedback_survey!(id), do: Repo.get!(FeedbackSurvey, id)

  @doc """
  Lists feedback surveys for a user, newest first.
  """
  def list_surveys_for_user(user_id) do
    FeedbackSurvey
    |> where([s], s.user_id == ^user_id)
    |> order_by([s], desc: s.inserted_at, desc: s.id)
    |> Repo.all()
  end

  @doc """
  Lists feedback surveys attached to a plan.
  """
  def list_surveys_for_plan(plan_id) do
    FeedbackSurvey
    |> where([s], s.plan_id == ^plan_id)
    |> order_by([s], asc: s.inserted_at, asc: s.id)
    |> Repo.all()
  end

  @doc """
  Stores responses on a survey and stamps completed_at.
  """
  def complete_survey(%FeedbackSurvey{} = survey, responses) when is_map(responses) do
    survey
    |> FeedbackSurvey.complete_changeset(responses)
    |> Repo.update()
  end
end
