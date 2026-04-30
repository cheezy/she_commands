defmodule SheCommands.Accounts.UserNotifierTest do
  use SheCommands.DataCase, async: true

  import SheCommands.AccountsFixtures
  import SheCommands.EscalationsFixtures
  import Swoosh.TestAssertions

  alias SheCommands.Accounts.UserNotifier

  describe "deliver_new_escalation_notification/3" do
    test "sends an email with subject, member name, and dashboard link" do
      coach = coach_fixture()

      member =
        user_fixture(%{})
        |> Ecto.Changeset.change(%{display_name: "Member Display"})
        |> SheCommands.Repo.update!()

      escalation = escalation_fixture(%{user: member, subject: :plan_clarification})
      escalation = %{escalation | user: member}

      assert {:ok, email} =
               UserNotifier.deliver_new_escalation_notification(
                 coach,
                 escalation,
                 "https://example.test/coach/escalations"
               )

      assert email.subject =~ "Plan clarification"
      assert email.text_body =~ "Member Display"
      assert email.text_body =~ "Plan clarification"
      assert email.text_body =~ "https://example.test/coach/escalations"
      assert_email_sent(email)
    end

    test "falls back to a generic name when display_name and name are blank" do
      coach = coach_fixture()
      member = user_fixture(%{})
      escalation = escalation_fixture(%{user: member, subject: :motivation_support})

      escalation_with_blank =
        %{escalation | user: %{member | display_name: nil, name: nil}}

      {:ok, email} =
        UserNotifier.deliver_new_escalation_notification(
          coach,
          escalation_with_blank,
          "https://example.test/coach/escalations"
        )

      assert email.text_body =~ "a member"
    end
  end

  describe "deliver_escalation_confirmation/2" do
    test "sends an SLA reminder and scope copy to the member" do
      member = user_fixture(%{})
      escalation = escalation_fixture(%{user: member, subject: :event_prioritization})

      assert {:ok, email} = UserNotifier.deliver_escalation_confirmation(member, escalation)

      assert email.subject =~ "received"
      assert email.text_body =~ "Event prioritization"
      assert email.text_body =~ "48 business hours"
      assert email.text_body =~ "qualified professional"
      assert_email_sent(email)
    end
  end

  describe "deliver_mid_plan_prompt/2" do
    test "subject is 'Was this week doable?' and body includes the in-app link" do
      member =
        user_fixture(%{})
        |> Ecto.Changeset.change(%{display_name: "DN"})
        |> SheCommands.Repo.update!()

      prompt = %SheCommands.Feedback.FeedbackPrompt{
        id: 42,
        prompt_type: :mid_plan,
        plan_id: 1,
        user_id: member.id
      }

      assert {:ok, email} = UserNotifier.deliver_mid_plan_prompt(member, prompt)
      assert email.subject == "Was this week doable?"
      assert email.text_body =~ "Hi DN,"
      assert email.text_body =~ "/feedback/prompts/42"
      assert_email_sent(email)
    end

    test "falls back to email when display_name and name are blank" do
      member = user_fixture(%{})

      prompt = %SheCommands.Feedback.FeedbackPrompt{
        id: 1,
        prompt_type: :mid_plan,
        plan_id: 1,
        user_id: member.id
      }

      blank_member = %{member | name: nil, display_name: nil}
      assert {:ok, email} = UserNotifier.deliver_mid_plan_prompt(blank_member, prompt)
      assert email.text_body =~ "Hi #{blank_member.email}"
    end
  end

  describe "deliver_post_plan_survey/2" do
    test "subject is 'How did your plan go?' and body lists three questions plus link" do
      member = user_fixture(%{})

      survey = %SheCommands.Feedback.FeedbackSurvey{
        id: 99,
        survey_type: :post_plan_review,
        plan_id: 1,
        user_id: member.id
      }

      assert {:ok, email} = UserNotifier.deliver_post_plan_survey(member, survey)
      assert email.subject == "How did your plan go?"
      assert email.text_body =~ "1. What worked best"
      assert email.text_body =~ "2. What got in the way"
      assert email.text_body =~ "3. What would you change"
      assert email.text_body =~ "/feedback/surveys/99"
    end
  end

  describe "deliver_feedback_prompt_email/2 dispatch" do
    test "mid_plan prompt routes to mid-plan email" do
      member = user_fixture(%{})

      prompt = %SheCommands.Feedback.FeedbackPrompt{
        id: 1,
        prompt_type: :mid_plan,
        plan_id: 1,
        user_id: member.id
      }

      assert {:ok, email} = UserNotifier.deliver_feedback_prompt_email(member, prompt)
      assert email.subject == "Was this week doable?"
    end
  end

  describe "create_escalation triggers" do
    test "sends a notification to every coach (excluding the member if they are a coach)" do
      coach_a = coach_fixture()
      coach_b = coach_fixture()
      member = user_fixture(%{})

      assert {:ok, _escalation} =
               member
               |> SheCommands.Accounts.Scope.for_user()
               |> SheCommands.Escalations.create_escalation(%{
                 subject: :plan_clarification,
                 user_note: "Help"
               })

      coach_a_to = [{"", coach_a.email}]
      coach_b_to = [{"", coach_b.email}]
      member_to = [{"", member.email}]

      assert_received {:email, %{to: ^coach_a_to, subject: "New escalation: Plan clarification"}}

      assert_received {:email, %{to: ^coach_b_to, subject: "New escalation: Plan clarification"}}

      assert_received {:email,
                       %{to: ^member_to, subject: "We received your coach review request"}}
    end

    test "sends a confirmation email to the member" do
      coach_fixture()
      member = user_fixture(%{})

      {:ok, _escalation} =
        member
        |> SheCommands.Accounts.Scope.for_user()
        |> SheCommands.Escalations.create_escalation(%{subject: :motivation_support})

      member_to = [{"", member.email}]

      assert_received {:email,
                       %{to: ^member_to, subject: "We received your coach review request"}}
    end

    test "no coaches in system — escalation still succeeds" do
      member = user_fixture(%{})

      assert {:ok, _escalation} =
               member
               |> SheCommands.Accounts.Scope.for_user()
               |> SheCommands.Escalations.create_escalation(%{subject: :plan_clarification})
    end

    test "does not notify the submitting coach themselves" do
      coach_member = coach_fixture()

      {:ok, _} =
        coach_member
        |> SheCommands.Accounts.Scope.for_user()
        |> SheCommands.Escalations.create_escalation(%{subject: :plan_clarification})

      # No coach-queue notification was sent (subject starts with "New escalation: ...")
      refute_email_sent(subject: "New escalation: Plan clarification")

      # The confirmation to the submitter still goes out
      coach_member_to = [{"", coach_member.email}]

      assert_received {:email,
                       %{to: ^coach_member_to, subject: "We received your coach review request"}}
    end
  end
end
