defmodule SheCommands.Feedback.Workers.PlanCompletionSurveyTest do
  use SheCommands.DataCase, async: true
  use Oban.Testing, repo: SheCommands.Repo

  import SheCommands.AccountsFixtures
  import SheCommands.PlansFixtures

  alias SheCommands.Feedback
  alias SheCommands.Feedback.Workers.PlanCompletionSurvey
  alias SheCommands.Plans

  describe "perform/1" do
    test "creates a post_plan_review survey" do
      user = user_fixture(%{})
      plan = plan_fixture(%{user: user, status: :active})
      Oban.drain_queue(queue: :feedback)

      :ok = perform_job(PlanCompletionSurvey, %{plan_id: plan.id})

      [survey] = Feedback.list_surveys_for_plan(plan.id)
      assert survey.survey_type == :post_plan_review
      assert survey.user_id == user.id
    end

    test "is idempotent — does not create a duplicate" do
      user = user_fixture(%{})
      plan = plan_fixture(%{user: user, status: :active})
      Oban.drain_queue(queue: :feedback)

      :ok = perform_job(PlanCompletionSurvey, %{plan_id: plan.id})
      :ok = perform_job(PlanCompletionSurvey, %{plan_id: plan.id})

      assert length(Feedback.list_surveys_for_plan(plan.id)) == 1
    end
  end

  describe "Plans.update_plan/2 trigger" do
    test "enqueues a PlanCompletionSurvey when status transitions to :completed" do
      user = user_fixture(%{})
      plan = plan_fixture(%{user: user, status: :active})
      Oban.drain_queue(queue: :feedback)

      assert {:ok, _completed} = Plans.update_plan(plan, %{status: :completed})

      assert_enqueued(worker: PlanCompletionSurvey, args: %{"plan_id" => plan.id})
    end

    test "does not re-enqueue when an already-completed plan is updated" do
      user = user_fixture(%{})
      plan = plan_fixture(%{user: user, status: :completed})
      Oban.drain_queue(queue: :feedback)

      Plans.update_plan(plan, %{status: :completed})

      refute_enqueued(worker: PlanCompletionSurvey)
    end
  end
end
