defmodule SheCommandsWeb.CoachLive.EscalationShowTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SheCommands.AccountsFixtures
  import SheCommands.EscalationsFixtures
  import SheCommands.PlansFixtures
  import SheCommands.ModulesFixtures
  import SheCommands.ChatFixtures

  alias SheCommands.Escalations

  setup :register_and_log_in_user

  describe "as a non-assigned coach" do
    setup %{user: user} do
      {:ok, _coach} = SheCommands.Accounts.update_user_role(user, :coach)
      :ok
    end

    test "redirects when escalation is unassigned", %{conn: conn} do
      escalation = escalation_fixture()

      assert {:error, {:redirect, %{to: "/coach/escalations"}}} =
               live(conn, ~p"/coach/escalations/#{escalation.id}")
    end

    test "redirects when escalation is assigned to another coach", %{conn: conn} do
      escalation = escalation_fixture()
      other_coach = coach_fixture()
      {:ok, _} = Escalations.assign_coach(escalation, other_coach.id)

      assert {:error, {:redirect, %{to: "/coach/escalations"}}} =
               live(conn, ~p"/coach/escalations/#{escalation.id}")
    end
  end

  describe "as the assigned coach" do
    setup %{user: user} do
      {:ok, coach} = SheCommands.Accounts.update_user_role(user, :coach)

      member =
        user_fixture(%{name: "Member Person"})
        |> Ecto.Changeset.change(%{
          display_name: "Member Display",
          city: "Toronto",
          province: "ON",
          country: "Canada"
        })
        |> SheCommands.Repo.update!()

      escalation =
        escalation_fixture(%{
          user: member,
          subject: :plan_clarification,
          user_note: "I want to refine my Power Up modules."
        })

      {:ok, escalation} = Escalations.assign_coach(escalation, coach.id)

      %{coach: coach, member: member, escalation: escalation}
    end

    test "renders the user profile and escalation metadata", %{
      conn: conn,
      escalation: escalation
    } do
      {:ok, _view, html} = live(conn, ~p"/coach/escalations/#{escalation.id}")

      assert html =~ "Member Display"
      assert html =~ "Toronto, ON, Canada"
      assert html =~ "Plan clarification"
      assert html =~ "I want to refine my Power Up modules."
      assert html =~ "Submitted"
      assert html =~ "SLA deadline"
    end

    test "renders the plan summary with modules grouped by pillar", %{
      conn: conn,
      member: member,
      escalation: escalation
    } do
      plan = plan_fixture(%{user: member, goal_statement: "Step into the boardroom."})

      module_a = module_fixture(%{title: "Daily Power Up Routine"})
      module_b = module_fixture(%{title: "Pre-meeting Composure"})

      plan_module_fixture(plan, %{module: module_a, power_pillar: :power_up, position: 1})
      plan_module_fixture(plan, %{module: module_b, power_pillar: :power_through, position: 2})

      Ecto.Changeset.change(escalation, %{plan_id: plan.id})
      |> SheCommands.Repo.update!()

      {:ok, _view, html} = live(conn, ~p"/coach/escalations/#{escalation.id}")

      assert html =~ "Step into the boardroom."
      assert html =~ "Power Up"
      assert html =~ "Daily Power Up Routine"
      assert html =~ "Power Through"
      assert html =~ "Pre-meeting Composure"
    end

    test "renders chat conversation context when chat_message is attached", %{
      conn: conn,
      member: member,
      escalation: escalation
    } do
      plan = plan_fixture(%{user: member})
      _msg1 = chat_message_fixture(%{user: member, plan: plan, role: :user, content: "First"})

      flagged =
        chat_message_fixture(%{user: member, plan: plan, role: :assistant, content: "Flagged"})

      _msg3 = chat_message_fixture(%{user: member, plan: plan, role: :user, content: "Third"})

      Ecto.Changeset.change(escalation, %{chat_message_id: flagged.id, plan_id: plan.id})
      |> SheCommands.Repo.update!()

      {:ok, _view, html} = live(conn, ~p"/coach/escalations/#{escalation.id}")

      assert html =~ "Conversation context"
      assert html =~ "First"
      assert html =~ "Flagged"
      assert html =~ "Third"
    end

    test "renders no-plan message when escalation has no plan_id", %{
      conn: conn,
      escalation: escalation
    } do
      {:ok, _view, html} = live(conn, ~p"/coach/escalations/#{escalation.id}")
      assert html =~ "No active plan attached"
    end

    test "submitting a response transitions to :responded with PubSub broadcast", %{
      conn: conn,
      escalation: escalation,
      member: member
    } do
      Escalations.subscribe_user(member.id)

      {:ok, view, _html} = live(conn, ~p"/coach/escalations/#{escalation.id}")

      html =
        view
        |> form("form", %{response: "Thanks for the context — here's how to proceed."})
        |> render_submit()

      assert html =~ "Response sent."
      assert html =~ "Responded"

      reloaded = SheCommands.Repo.get!(SheCommands.Escalations.Escalation, escalation.id)
      assert reloaded.status == :responded
      assert reloaded.coach_response =~ "here's how to proceed."
      assert reloaded.responded_at

      assert_receive {:escalation_updated, %{status: :responded}}, 500
    end

    test "submitting an empty response shows a validation flash without changing status", %{
      conn: conn,
      escalation: escalation
    } do
      {:ok, view, _html} = live(conn, ~p"/coach/escalations/#{escalation.id}")

      html =
        view
        |> form("form", %{response: "   "})
        |> render_submit()

      assert html =~ "Please enter a response before submitting."

      reloaded = SheCommands.Repo.get!(SheCommands.Escalations.Escalation, escalation.id)
      assert reloaded.status == :in_review
    end
  end

  describe "as an admin" do
    setup %{user: user} do
      {:ok, _admin} = SheCommands.Accounts.update_user_role(user, :admin)
      :ok
    end

    test "admin can view an escalation assigned to another coach", %{conn: conn} do
      escalation = escalation_fixture()
      other_coach = coach_fixture()
      {:ok, _} = Escalations.assign_coach(escalation, other_coach.id)

      {:ok, _view, html} = live(conn, ~p"/coach/escalations/#{escalation.id}")
      assert html =~ "Plan clarification"
    end
  end
end
