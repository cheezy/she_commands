defmodule SheCommands.Feedback.Workers.FeedbackDeliveryTest do
  use SheCommands.DataCase, async: true
  use Oban.Testing, repo: SheCommands.Repo

  import SheCommands.AccountsFixtures
  import SheCommands.FeedbackFixtures
  import Swoosh.TestAssertions

  alias SheCommands.Feedback
  alias SheCommands.Feedback.Workers.FeedbackDelivery

  describe "perform/1" do
    test "sends an email and transitions the prompt to :sent" do
      user = user_fixture(%{})
      prompt = feedback_prompt_fixture(%{user: user, prompt_type: :mid_plan})

      :ok = perform_job(FeedbackDelivery, %{prompt_id: prompt.id})

      reloaded = Feedback.get_feedback_prompt!(prompt.id)
      assert reloaded.status == :sent
      assert reloaded.sent_at

      to = [{"", user.email}]
      assert_received {:email, %{to: ^to, subject: "How is your plan going?"}}
    end

    test "is idempotent — already-sent prompts are short-circuited" do
      user = user_fixture(%{})
      prompt = feedback_prompt_fixture(%{user: user})
      {:ok, _} = Feedback.mark_prompt_sent(prompt)

      :ok = perform_job(FeedbackDelivery, %{prompt_id: prompt.id})

      refute_email_sent(subject: "How is your plan going?")

      reloaded = Feedback.get_feedback_prompt!(prompt.id)
      # sent_at is still the original timestamp from mark_prompt_sent, not reset
      assert reloaded.status == :sent
    end

    test "responded prompts do not trigger another email" do
      prompt = feedback_prompt_fixture()
      {:ok, _} = Feedback.mark_prompt_responded(prompt, "All good")

      :ok = perform_job(FeedbackDelivery, %{prompt_id: prompt.id})

      refute_email_sent(subject: "How is your plan going?")
    end
  end
end
