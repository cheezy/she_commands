defmodule SheCommandsWeb.EscalationLive.MemberComponentTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SheCommands.EscalationsFixtures

  alias SheCommands.Escalations

  setup :register_and_log_in_user

  describe "form rendering" do
    test "renders the request form with all three subjects", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/coach-review")

      assert html =~ "Request coach review"
      assert html =~ "Plan clarification"
      assert html =~ "Motivation support"
      assert html =~ "Event prioritization"
      assert html =~ "Note (optional)"
    end

    test "communicates scope limitations", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/coach-review")

      assert html =~ "Coach support covers"
      assert html =~ "qualified professional"
    end

    test "shows the empty-state message when the user has no escalations", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/coach-review")
      assert html =~ "You have not requested coach review yet."
    end
  end

  describe "submit_escalation event" do
    test "creates a pending escalation and shows the success message", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/coach-review")

      html =
        view
        |> form("form", %{subject: "plan_clarification", user_note: "Need help"})
        |> render_submit()

      assert html =~ "Your request has been sent to a coach."
      assert html =~ "Pending"
      assert html =~ "Need help"

      [escalation] =
        user
        |> SheCommands.Accounts.Scope.for_user()
        |> Escalations.list_escalations_for_user()

      assert escalation.subject == :plan_clarification
      assert escalation.status == :pending
    end

    test "shows an error message when subject is blank", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/coach-review")

      html =
        view
        |> form("form", %{subject: "", user_note: ""})
        |> render_submit()

      assert html =~ "Please choose a subject before submitting."
      refute html =~ "Pending"
    end
  end

  describe "status panel" do
    test "renders pending and in-review escalations with status labels", %{
      conn: conn,
      user: user
    } do
      pending = escalation_fixture(%{user: user, subject: :plan_clarification})

      coach = SheCommands.AccountsFixtures.coach_fixture(%{})
      review_target = escalation_fixture(%{user: user, subject: :motivation_support})
      {:ok, _} = Escalations.assign_coach(review_target, coach.id)

      {:ok, _view, html} = live(conn, ~p"/coach-review")

      assert html =~ "Plan clarification"
      assert html =~ "Pending"
      assert html =~ "Motivation support"
      assert html =~ "In review"
      assert pending.id
    end

    test "shows the coach response when an escalation is responded", %{conn: conn, user: user} do
      escalation = escalation_fixture(%{user: user, subject: :event_prioritization})
      {:ok, _} = Escalations.respond_to_escalation(escalation, "Here is your guidance.")

      {:ok, _view, html} = live(conn, ~p"/coach-review")

      assert html =~ "Responded"
      assert html =~ "Coach response"
      assert html =~ "Here is your guidance."
    end

    test "scopes the list to the current user", %{conn: conn, user: user} do
      other = SheCommands.AccountsFixtures.user_fixture(%{})
      escalation_fixture(%{user: other, subject: :plan_clarification, user_note: "Other note"})
      escalation_fixture(%{user: user, subject: :motivation_support, user_note: "Mine"})

      {:ok, _view, html} = live(conn, ~p"/coach-review")

      assert html =~ "Mine"
      refute html =~ "Other note"
    end
  end

  describe "real-time updates via PubSub" do
    test "list refreshes when an escalation is responded by a coach", %{conn: conn, user: user} do
      escalation = escalation_fixture(%{user: user, subject: :plan_clarification})

      {:ok, view, html_before} = live(conn, ~p"/coach-review")
      refute html_before =~ "Responded"

      {:ok, _} = Escalations.respond_to_escalation(escalation, "Coach reply.")

      _ = :sys.get_state(view.pid)
      html_after = render(view)
      assert html_after =~ "Responded"
      assert html_after =~ "Coach reply."
    end
  end
end
