defmodule SheCommands.Feedback.Workers.PlanCompletionSurvey do
  @moduledoc """
  Oban worker that creates a `:post_plan_review` `FeedbackSurvey` row
  when a plan is completed.

  Idempotent: if a post-plan survey already exists for the plan, no new
  survey is created.
  """

  use Oban.Worker, queue: :feedback, max_attempts: 3

  alias SheCommands.Feedback
  alias SheCommands.Feedback.FeedbackSurvey
  alias SheCommands.Plans

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"plan_id" => plan_id}}) do
    plan = Plans.get_plan!(plan_id)

    if survey_exists?(plan_id) do
      :ok
    else
      {:ok, _survey} =
        Feedback.create_feedback_survey(%{
          plan_id: plan_id,
          user_id: plan.user_id,
          survey_type: :post_plan_review
        })

      :ok
    end
  end

  defp survey_exists?(plan_id) do
    plan_id
    |> Feedback.list_surveys_for_plan()
    |> Enum.any?(fn %FeedbackSurvey{survey_type: t} -> t == :post_plan_review end)
  end
end
