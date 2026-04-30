defmodule SheCommandsWeb.CoachLive.EscalationIndexTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SheCommands.AccountsFixtures
  import SheCommands.EscalationsFixtures

  alias SheCommands.Escalations
  alias SheCommandsWeb.CoachLive.EscalationIndex

  setup :register_and_log_in_user

  defp member_with_display_name(name) do
    user = user_fixture(%{})

    user
    |> Ecto.Changeset.change(%{display_name: name})
    |> SheCommands.Repo.update!()
  end

  describe "authorization" do
    test "redirects member users", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/coach/escalations")
    end
  end

  describe "as a coach" do
    setup %{user: user} do
      {:ok, coach} = SheCommands.Accounts.update_user_role(user, :coach)
      %{coach: coach}
    end

    test "renders the empty state when there are no pending escalations", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/coach/escalations")

      assert html =~ "Escalations queue"
      assert html =~ "No pending escalations."
      assert html =~ "Pending"
      assert html =~ "Overdue"
    end

    test "lists pending escalations ordered by SLA deadline (most urgent first)", %{conn: conn} do
      member_a = member_with_display_name("Avery")
      member_b = member_with_display_name("Beth")

      _later = escalation_fixture(%{user: member_a, subject: :plan_clarification})
      sooner = escalation_fixture(%{user: member_b, subject: :motivation_support})

      # Force `sooner` to have an earlier deadline
      sooner_past =
        DateTime.utc_now()
        |> DateTime.add(-3600, :second)
        |> DateTime.truncate(:second)

      Ecto.Changeset.change(sooner, %{sla_deadline: sooner_past})
      |> SheCommands.Repo.update!()

      {:ok, _view, html} = live(conn, ~p"/coach/escalations")

      avery_index = :binary.match(html, "Avery") |> elem(0)
      beth_index = :binary.match(html, "Beth") |> elem(0)
      assert beth_index < avery_index
      assert html =~ "SLA overdue"
    end

    test "uses display_name not email for the member label", %{conn: conn} do
      member = member_with_display_name("Friendly Name")
      escalation_fixture(%{user: member})

      {:ok, _view, html} = live(conn, ~p"/coach/escalations")
      assert html =~ "Friendly Name"
      refute html =~ member.email
    end

    test "claim button assigns the coach and removes the escalation from the queue", %{
      conn: conn,
      coach: coach
    } do
      member = member_with_display_name("Member One")
      escalation = escalation_fixture(%{user: member})

      {:ok, view, _html} = live(conn, ~p"/coach/escalations")
      html = render_click(view, "claim", %{"id" => escalation.id})

      refute html =~ "Member One"
      assert html =~ "Escalation claimed."

      reloaded = SheCommands.Repo.get!(SheCommands.Escalations.Escalation, escalation.id)
      assert reloaded.coach_id == coach.id
      assert reloaded.status == :in_review
    end

    test "header shows pending, in-review, and overdue counts", %{conn: conn, coach: coach} do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      past = DateTime.add(now, -3600, :second)

      _pending = escalation_fixture()
      _pending2 = escalation_fixture()

      reviewing = escalation_fixture()
      {:ok, _} = Escalations.assign_coach(reviewing, coach.id)

      overdue = escalation_fixture()

      Ecto.Changeset.change(overdue, %{sla_deadline: past})
      |> SheCommands.Repo.update!()

      {:ok, _view, html} = live(conn, ~p"/coach/escalations")

      assert html =~ "Pending"
      assert html =~ "In review"
      assert html =~ "Overdue"
    end

    test "queue refreshes via PubSub when a new escalation arrives", %{conn: conn} do
      {:ok, view, html_before} = live(conn, ~p"/coach/escalations")
      refute html_before =~ "Late Joiner"

      member = member_with_display_name("Late Joiner")
      escalation_fixture(%{user: member, subject: :event_prioritization})

      # Force the LiveView process to drain its mailbox (handle_info from PubSub)
      _ = :sys.get_state(view.pid)

      html_after = render(view)
      assert html_after =~ "Late Joiner"
      assert html_after =~ "Event prioritization"
    end
  end

  describe "sla_urgency/2" do
    test "returns :overdue when the deadline has passed" do
      now = ~U[2026-05-04 12:00:00Z]
      deadline = ~U[2026-05-04 11:00:00Z]
      assert EscalationIndex.sla_urgency(deadline, now) == :overdue
    end

    test "returns :red when less than 12 hours remain" do
      now = ~U[2026-05-04 12:00:00Z]
      deadline = ~U[2026-05-04 23:00:00Z]
      assert EscalationIndex.sla_urgency(deadline, now) == :red
    end

    test "returns :yellow when 12 to 24 hours remain" do
      now = ~U[2026-05-04 12:00:00Z]
      deadline = ~U[2026-05-05 06:00:00Z]
      assert EscalationIndex.sla_urgency(deadline, now) == :yellow
    end

    test "returns :green when more than 24 hours remain" do
      now = ~U[2026-05-04 12:00:00Z]
      deadline = ~U[2026-05-06 14:00:00Z]
      assert EscalationIndex.sla_urgency(deadline, now) == :green
    end
  end

  describe "humanize_remaining/1" do
    test "negative is overdue" do
      assert EscalationIndex.humanize_remaining(-1) == "overdue"
    end

    test "less than an hour is under 1 hour" do
      assert EscalationIndex.humanize_remaining(1500) == "under 1 hour"
    end

    test "hours format" do
      assert EscalationIndex.humanize_remaining(2 * 3600) == "2 hours"
    end

    test "days format" do
      assert EscalationIndex.humanize_remaining(3 * 86_400) == "3 days"
    end
  end

  describe "display_name/1" do
    test "uses display_name when present" do
      assert EscalationIndex.display_name(%{display_name: "DN", name: "N"}) == "DN"
    end

    test "falls back to name when display_name is blank" do
      assert EscalationIndex.display_name(%{display_name: "", name: "Fallback"}) == "Fallback"
    end

    test "falls back to Member when both are blank" do
      assert EscalationIndex.display_name(%{display_name: nil, name: nil}) == "Member"
    end
  end

  describe "subscribe_pending broadcasts" do
    test "create_escalation broadcasts to the pending topic" do
      Escalations.subscribe_pending()
      member = user_fixture(%{display_name: "Sub Test"})

      _ = escalation_fixture(%{user: member, subject: :plan_clarification})

      assert_receive {:pending_changed, _escalation}, 500
    end

    test "assign_coach broadcasts to the pending topic" do
      member = user_fixture(%{})
      coach = coach_fixture()
      escalation = escalation_fixture(%{user: member})

      Escalations.subscribe_pending()
      {:ok, _} = Escalations.assign_coach(escalation, coach.id)

      assert_receive {:pending_changed, _escalation}, 500
    end
  end
end
