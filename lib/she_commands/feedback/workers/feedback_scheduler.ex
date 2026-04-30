defmodule SheCommands.Feedback.Workers.FeedbackScheduler do
  @moduledoc """
  Oban worker that schedules a mid-plan feedback prompt for a plan.

  Runs once per plan when the plan is activated. Calculates the
  mid-plan delivery date based on `plan_type`:

    * `:weekly`   — day 4 of 7
    * `:biweekly` — day 8 of 14
    * `:monthly`  — day 15 of 30

  Idempotent: if a `:mid_plan` prompt already exists for the plan, no
  new prompt is created and no delivery job is enqueued.
  """

  use Oban.Worker, queue: :feedback, max_attempts: 3

  alias SheCommands.Feedback
  alias SheCommands.Feedback.FeedbackPrompt
  alias SheCommands.Feedback.Workers.FeedbackDelivery
  alias SheCommands.Plans

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"plan_id" => plan_id}}) do
    plan = Plans.get_plan!(plan_id)

    if mid_plan_prompt_exists?(plan_id) do
      :ok
    else
      scheduled_for = mid_plan_offset(plan.plan_type, plan.inserted_at)

      {:ok, prompt} =
        Feedback.create_feedback_prompt(%{
          plan_id: plan_id,
          user_id: plan.user_id,
          prompt_type: :mid_plan,
          scheduled_for: scheduled_for
        })

      %{prompt_id: prompt.id}
      |> FeedbackDelivery.new(scheduled_at: scheduled_for)
      |> Oban.insert()

      :ok
    end
  end

  @doc """
  Returns the scheduled mid-plan delivery datetime for the given
  `plan_type`, anchored at `start`.
  """
  def mid_plan_offset(plan_type, %DateTime{} = start) do
    days = mid_plan_days(plan_type)

    start
    |> DateTime.add(days * 86_400, :second)
    |> DateTime.truncate(:second)
  end

  defp mid_plan_days(:weekly), do: 4
  defp mid_plan_days(:biweekly), do: 8
  defp mid_plan_days(:monthly), do: 15
  defp mid_plan_days(_), do: 4

  defp mid_plan_prompt_exists?(plan_id) do
    plan_id
    |> Feedback.list_prompts_for_plan()
    |> Enum.any?(fn %FeedbackPrompt{prompt_type: t} -> t == :mid_plan end)
  end
end
