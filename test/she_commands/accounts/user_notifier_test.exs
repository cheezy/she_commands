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
