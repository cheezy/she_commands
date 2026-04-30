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

  describe "submit_response defense in depth" do
    test "redirects when the user lost authorization between mount and submit", %{
      conn: conn,
      user: user
    } do
      {:ok, coach} = SheCommands.Accounts.update_user_role(user, :coach)
      escalation = escalation_fixture(%{subject: :plan_clarification})
      {:ok, _} = Escalations.assign_coach(escalation, coach.id)

      {:ok, view, _html} = live(conn, ~p"/coach/escalations/#{escalation.id}")

      # Reassign to another coach (the test user no longer owns the escalation)
      other_coach = coach_fixture()

      Ecto.Changeset.change(escalation, %{coach_id: other_coach.id})
      |> SheCommands.Repo.update!()

      # Force the LiveView's escalation assign to reflect the new coach_id so
      # the submit-time authorized? check fails.
      :sys.replace_state(view.pid, fn s ->
        new_escalation = %{s.socket.assigns.escalation | coach_id: other_coach.id}
        new_assigns = Map.put(s.socket.assigns, :escalation, new_escalation)
        new_socket = %{s.socket | assigns: new_assigns}
        %{s | socket: new_socket}
      end)

      assert {:error, {:redirect, %{to: "/coach/escalations"}}} =
               view
               |> form("form", %{response: "Late response"})
               |> render_submit()
    end
  end

  describe "responded escalation view" do
    setup %{user: user} do
      {:ok, coach} = SheCommands.Accounts.update_user_role(user, :coach)
      member = user_fixture(%{})

      escalation =
        escalation_fixture(%{
          user: member,
          subject: :motivation_support,
          user_note: "Need encouragement"
        })

      {:ok, escalation} = Escalations.assign_coach(escalation, coach.id)

      {:ok, escalation} =
        Escalations.respond_to_escalation(escalation, "Already-sent encouragement.")

      %{coach: coach, member: member, escalation: escalation}
    end

    test "pre-fills the textarea with the existing coach_response", %{
      conn: conn,
      escalation: escalation
    } do
      {:ok, _view, html} = live(conn, ~p"/coach/escalations/#{escalation.id}")
      assert html =~ "Already-sent encouragement."
    end

    test "shows the Responded status label", %{conn: conn, escalation: escalation} do
      {:ok, _view, html} = live(conn, ~p"/coach/escalations/#{escalation.id}")
      assert html =~ "Responded"
    end
  end

  describe "closed escalation view" do
    test "shows the Closed status label", %{conn: conn, user: user} do
      {:ok, coach} = SheCommands.Accounts.update_user_role(user, :coach)
      escalation = escalation_fixture()
      {:ok, escalation} = Escalations.assign_coach(escalation, coach.id)
      {:ok, escalation} = Escalations.respond_to_escalation(escalation, "Done")
      {:ok, _} = Escalations.close_escalation(escalation)

      {:ok, _view, html} = live(conn, ~p"/coach/escalations/#{escalation.id}")
      assert html =~ "Closed"
    end
  end

  describe "subject and pillar label coverage" do
    setup %{user: user} do
      {:ok, coach} = SheCommands.Accounts.update_user_role(user, :coach)
      %{coach: coach}
    end

    test "renders Motivation support subject", %{conn: conn, coach: coach} do
      escalation = escalation_fixture(%{subject: :motivation_support})
      {:ok, _} = Escalations.assign_coach(escalation, coach.id)

      {:ok, _view, html} = live(conn, ~p"/coach/escalations/#{escalation.id}")
      assert html =~ "Motivation support"
    end

    test "renders Event prioritization subject", %{conn: conn, coach: coach} do
      escalation = escalation_fixture(%{subject: :event_prioritization})
      {:ok, _} = Escalations.assign_coach(escalation, coach.id)

      {:ok, _view, html} = live(conn, ~p"/coach/escalations/#{escalation.id}")
      assert html =~ "Event prioritization"
    end

    test "renders Power Down and Empower pillars in the plan summary", %{
      conn: conn,
      coach: coach
    } do
      member = user_fixture(%{})
      plan = plan_fixture(%{user: member})

      power_down = module_fixture(%{title: "Sleep Routine"})
      empower = module_fixture(%{title: "Goal Setting"})

      plan_module_fixture(plan, %{module: power_down, power_pillar: :power_down, position: 1})
      plan_module_fixture(plan, %{module: empower, power_pillar: :empower, position: 2})

      escalation = escalation_fixture(%{user: member})
      {:ok, escalation} = Escalations.assign_coach(escalation, coach.id)

      Ecto.Changeset.change(escalation, %{plan_id: plan.id})
      |> SheCommands.Repo.update!()

      {:ok, _view, html} = live(conn, ~p"/coach/escalations/#{escalation.id}")

      assert html =~ "Power Down"
      assert html =~ "Sleep Routine"
      assert html =~ "Empower"
      assert html =~ "Goal Setting"
    end
  end

  describe "display_name/1" do
    alias SheCommandsWeb.CoachLive.EscalationShow

    test "uses display_name when present" do
      assert EscalationShow.display_name(%{display_name: "DN", name: "N"}) == "DN"
    end

    test "falls back to name when display_name is blank" do
      assert EscalationShow.display_name(%{display_name: "", name: "Fallback"}) == "Fallback"
    end

    test "falls back to Member when both are blank or nil" do
      assert EscalationShow.display_name(%{display_name: nil, name: nil}) == "Member"
      assert EscalationShow.display_name(%{display_name: "", name: ""}) == "Member"
    end
  end

  describe "location/1" do
    alias SheCommandsWeb.CoachLive.EscalationShow

    test "joins city / province / country with commas" do
      user = %{city: "Toronto", province: "ON", country: "Canada"}
      assert EscalationShow.location(user) == "Toronto, ON, Canada"
    end

    test "skips nil and blank fields" do
      user = %{city: "Toronto", province: nil, country: ""}
      assert EscalationShow.location(user) == "Toronto"
    end

    test "returns empty string when all fields are blank" do
      user = %{city: nil, province: "", country: nil}
      assert EscalationShow.location(user) == ""
    end
  end

  describe "pillar_label/1 fallback" do
    alias SheCommandsWeb.CoachLive.EscalationShow

    test "capitalizes unknown atoms" do
      assert EscalationShow.pillar_label(:custom_thing) == "Custom_thing"
    end
  end

  describe "renders escalation with no plan and no chat message gracefully" do
    test "shows the no-plan message and hides the chat-context section", %{conn: conn, user: user} do
      {:ok, coach} = SheCommands.Accounts.update_user_role(user, :coach)
      escalation = escalation_fixture()
      {:ok, _} = Escalations.assign_coach(escalation, coach.id)

      {:ok, _view, html} = live(conn, ~p"/coach/escalations/#{escalation.id}")

      assert html =~ "No active plan attached"
      refute html =~ "Conversation context"
    end
  end
end
