defmodule SheCommands.Feedback.Workers.FeedbackSchedulerTest do
  use SheCommands.DataCase, async: true
  use Oban.Testing, repo: SheCommands.Repo

  import SheCommands.AccountsFixtures
  import SheCommands.PlansFixtures

  alias SheCommands.Feedback
  alias SheCommands.Feedback.Workers.FeedbackDelivery
  alias SheCommands.Feedback.Workers.FeedbackScheduler

  describe "mid_plan_offset/2" do
    test "weekly plans schedule on day 4" do
      start = ~U[2026-05-01 12:00:00Z]
      assert FeedbackScheduler.mid_plan_offset(:weekly, start) == ~U[2026-05-05 12:00:00Z]
    end

    test "biweekly plans schedule on day 8" do
      start = ~U[2026-05-01 12:00:00Z]
      assert FeedbackScheduler.mid_plan_offset(:biweekly, start) == ~U[2026-05-09 12:00:00Z]
    end

    test "monthly plans schedule on day 15" do
      start = ~U[2026-05-01 12:00:00Z]
      assert FeedbackScheduler.mid_plan_offset(:monthly, start) == ~U[2026-05-16 12:00:00Z]
    end
  end

  describe "perform/1" do
    test "creates a mid_plan FeedbackPrompt with the correct scheduled_for" do
      user = user_fixture(%{})
      plan = plan_fixture(%{user: user, plan_type: :weekly, status: :active})
      Oban.drain_queue(queue: :feedback)

      :ok = perform_job(FeedbackScheduler, %{plan_id: plan.id})

      [prompt] = Feedback.list_prompts_for_plan(plan.id)
      assert prompt.prompt_type == :mid_plan
      assert prompt.user_id == user.id
      assert prompt.status == :pending
      assert prompt.scheduled_for == FeedbackScheduler.mid_plan_offset(:weekly, plan.inserted_at)
    end

    test "is idempotent — running twice does not create a second prompt" do
      user = user_fixture(%{})
      plan = plan_fixture(%{user: user, plan_type: :biweekly, status: :active})
      Oban.drain_queue(queue: :feedback)

      :ok = perform_job(FeedbackScheduler, %{plan_id: plan.id})
      :ok = perform_job(FeedbackScheduler, %{plan_id: plan.id})

      assert length(Feedback.list_prompts_for_plan(plan.id)) == 1
    end

    test "enqueues a FeedbackDelivery job for the prompt" do
      user = user_fixture(%{})
      plan = plan_fixture(%{user: user, plan_type: :weekly, status: :active})
      Oban.drain_queue(queue: :feedback)

      :ok = perform_job(FeedbackScheduler, %{plan_id: plan.id})

      [prompt] = Feedback.list_prompts_for_plan(plan.id)
      assert_enqueued(worker: FeedbackDelivery, args: %{"prompt_id" => prompt.id})
    end
  end

  describe "Plans.create_plan/1 trigger" do
    test "enqueues a FeedbackScheduler job when status: :active" do
      user = user_fixture(%{})

      assert {:ok, plan} =
               SheCommands.Plans.create_plan(%{
                 user_id: user.id,
                 plan_type: :weekly,
                 status: :active
               })

      assert_enqueued(worker: FeedbackScheduler, args: %{"plan_id" => plan.id})
    end

    test "does not enqueue when status: :generating" do
      user = user_fixture(%{})

      assert {:ok, _plan} =
               SheCommands.Plans.create_plan(%{
                 user_id: user.id,
                 plan_type: :weekly,
                 status: :generating
               })

      refute_enqueued(worker: FeedbackScheduler)
    end
  end
end
