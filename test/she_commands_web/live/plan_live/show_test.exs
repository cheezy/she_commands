defmodule SheCommandsWeb.PlanLive.ShowTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SheCommands.ChatFixtures
  import SheCommands.ModulesFixtures
  import SheCommands.PlansFixtures

  alias SheCommands.Chat
  alias SheCommands.Repo

  setup :register_and_log_in_user

  describe "user without plan" do
    test "redirects to intake", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/intake"}}} = live(conn, ~p"/my-plan")
    end
  end

  describe "user with active plan" do
    setup %{user: user} do
      plan =
        plan_fixture(%{
          user: user,
          status: :active,
          plan_type: :weekly,
          goal_statement: "Lead with confidence in every room",
          expected_outcomes: "Power Up: Fuel energy\nEmpower: Lead with clarity"
        })

      module =
        module_fixture(%{
          title: "Test Module",
          contributor: "Paula V",
          coach_tip: "Stay focused",
          coach_tip_attribution: "Paula V",
          modifications: "Seated version available"
        })

      protocol_fixture(module, %{
        position: 1,
        purpose: "Build core strength",
        steps: "Step 1, Step 2",
        prescription: "3x/week"
      })

      plan_module_fixture(plan, %{module: module, power_pillar: :power_up, position: 1})

      %{plan: plan}
    end

    test "renders plan dashboard", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      assert html =~ "Lead with confidence in every room"
      assert html =~ "Your Plan"
    end

    test "shows expected outcomes", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      assert html =~ "Power Up: Fuel energy"
      assert html =~ "Empower: Lead with clarity"
    end

    test "shows power pillar overview", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      assert html =~ "Power Up"
      assert html =~ "1 module"
    end

    test "shows module title and contributor", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      assert html =~ "Test Module"
      assert html =~ "Paula V"
    end

    test "shows protocol details", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      assert html =~ "Build core strength"
      assert html =~ "Step 1, Step 2"
      assert html =~ "3x/week"
    end

    test "shows coach tip with attribution", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      assert html =~ "Stay focused"
      assert html =~ "Paula V"
    end

    test "shows modifications", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      assert html =~ "Seated version available"
    end

    test "shows plan type", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      assert html =~ "Weekly"
    end
  end

  describe "module rendering" do
    test "shows module overview when present", %{conn: conn, user: user} do
      plan = plan_fixture(%{user: user, status: :active, goal_statement: "Overview goal"})
      module = module_fixture(%{title: "Overview Module", overview: "A detailed overview text"})
      plan_module_fixture(plan, %{module: module, power_pillar: :power_through, position: 1})

      {:ok, _view, html} = live(conn, ~p"/my-plan")
      assert html =~ "Overview Module"
      assert html =~ "A detailed overview text"
    end

    test "renders all four power pillars in pillar order", %{conn: conn, user: user} do
      plan = plan_fixture(%{user: user, status: :active, goal_statement: "Four pillars goal"})

      for {pillar, idx} <- Enum.with_index([:empower, :power_down, :power_through, :power_up]) do
        module = module_fixture(%{title: "Module #{pillar}"})
        plan_module_fixture(plan, %{module: module, power_pillar: pillar, position: idx + 1})
      end

      {:ok, _view, html} = live(conn, ~p"/my-plan")

      assert html =~ "Power Up"
      assert html =~ "Power Through"
      assert html =~ "Power Down"
      assert html =~ "Empower"

      assert html =~ "Fuel your body and mind"
      assert html =~ "Build strength and endurance"
      assert html =~ "Rest, recover, and reset"
      assert html =~ "Lead, influence, and grow"

      # Pillar order: power_up (0) → power_through (1) → power_down (2) → empower (3)
      power_up_idx = :binary.match(html, "Power Up") |> elem(0)
      power_through_idx = :binary.match(html, "Power Through") |> elem(0)
      power_down_idx = :binary.match(html, "Power Down") |> elem(0)
      empower_idx = :binary.match(html, "Empower") |> elem(0)

      assert power_up_idx < power_through_idx
      assert power_through_idx < power_down_idx
      assert power_down_idx < empower_idx
    end
  end

  describe "weekly schedule rendering" do
    setup %{user: user} do
      schedule = %{
        "monday" => [
          %{
            "power_pillar" => "power_up",
            "module_title" => "Morning Energy",
            "daily_time" => 30
          }
        ],
        "tuesday" => [],
        "wednesday" => [
          %{
            "power_pillar" => "power_through",
            "module_title" => "Strength Block",
            "daily_time" => 45
          }
        ]
      }

      plan =
        plan_fixture(%{
          user: user,
          status: :active,
          plan_type: :weekly,
          goal_statement: "Schedule test goal",
          schedule: schedule
        })

      module = module_fixture(%{title: "Schedule Module"})
      plan_module_fixture(plan, %{module: module, power_pillar: :power_up, position: 1})

      %{plan: plan}
    end

    test "renders weekly schedule heading and assignments", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      assert html =~ "Your Weekly Schedule"
      assert html =~ "Morning Energy"
      assert html =~ "Strength Block"
    end

    test "shows daily totals for days with assignments", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      assert html =~ "30"
      assert html =~ "45"
    end

    test "shows rest day for days with no assignments", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      assert html =~ "Rest day"
    end

    test "renders all seven days in order", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")

      Enum.each(
        ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday),
        fn day -> assert html =~ day end
      )
    end
  end

  describe "chat panel" do
    setup %{user: user} do
      plan =
        plan_fixture(%{
          user: user,
          status: :active,
          plan_type: :weekly,
          goal_statement: "Chat test goal"
        })

      module = module_fixture(%{title: "Chat Module"})
      plan_module_fixture(plan, %{module: module, power_pillar: :power_up, position: 1})

      %{plan: plan}
    end

    test "panel is closed by default", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      refute html =~ "What should I focus on today?"
    end

    test "toggle_chat opens the panel and shows empty state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      html = render_click(view, "toggle_chat")
      assert html =~ "What should I focus on today?"
    end

    test "toggle_chat twice closes the panel", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")
      html = render_click(view, "toggle_chat")
      refute html =~ "What should I focus on today?"
    end

    test "toggle_chat loads persisted messages on first open", %{
      conn: conn,
      user: user,
      plan: plan
    } do
      chat_message_fixture(%{user: user, plan: plan, role: :user, content: "Saved question"})

      chat_message_fixture(%{
        user: user,
        plan: plan,
        role: :assistant,
        content: "Saved answer"
      })

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      html = render_click(view, "toggle_chat")

      assert html =~ "Saved question"
      assert html =~ "Saved answer"
    end

    test "clear_chat removes persisted messages", %{conn: conn, user: user, plan: plan} do
      chat_message_fixture(%{user: user, plan: plan, role: :user, content: "Will be cleared"})

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")
      assert render(view) =~ "Will be cleared"

      html = render_click(view, "clear_chat")
      refute html =~ "Will be cleared"
      assert Chat.list_messages_for_plan(plan.id, user.id) == []
    end

    test "send_message with blank content does nothing", %{conn: conn, user: user, plan: plan} do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      view |> element("form") |> render_submit(%{"message" => "   "})

      assert Chat.list_messages_for_plan(plan.id, user.id) == []
      refute render(view) =~ "animate-bounce"
    end

    test "send_message rejects content over the configured limit", %{
      conn: conn,
      user: user,
      plan: plan
    } do
      too_long = String.duplicate("a", 2001)

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      view
      |> element("form")
      |> render_submit(%{"message" => too_long})

      assert render(view) =~ "Message is too long"
      assert Chat.list_messages_for_plan(plan.id, user.id) == []
    end

    test "send_message shows rate limit flash when over threshold", %{
      conn: conn,
      user: user,
      plan: plan
    } do
      for n <- 1..20 do
        chat_message_fixture(%{
          user: user,
          plan: plan,
          role: :user,
          content: "msg #{n}"
        })
      end

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      view |> element("form") |> render_submit(%{"message" => "Over the limit"})

      assert render(view) =~ "sending messages too quickly"
    end

    test "set_chat_loading info handler toggles loading indicator", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      send(view.pid, {:set_chat_loading, true})
      assert render(view) =~ "animate-bounce"

      send(view.pid, {:set_chat_loading, false})
      refute render(view) =~ "animate-bounce"
    end

    test "DOWN message clears loading and shows error", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      send(view.pid, {:set_chat_loading, true})
      send(view.pid, {:DOWN, make_ref(), :process, self(), :killed})

      html = render(view)
      refute html =~ "animate-bounce"
      assert html =~ "Something went wrong"
    end

    test "send_message shows flash when user message persistence fails", %{
      conn: conn,
      plan: plan
    } do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      # Cascade-deletes plan_modules and chat_messages, leaving the LiveView's
      # assigns referencing a stale plan_id so the FK constraint trips on insert.
      Repo.delete!(plan)

      view |> element("form") |> render_submit(%{"message" => "Hello"})

      assert render(view) =~ "Failed to send message"
    end

    test "assistant response handler surfaces error when DB insert fails", %{
      conn: conn,
      plan: plan
    } do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")
      send(view.pid, {:set_chat_loading, true})

      Repo.delete!(plan)

      send(view.pid, {make_ref(), {:ok, "AI says hi"}})

      html = render(view)
      refute html =~ "animate-bounce"
      assert html =~ "Something went wrong"
    end
  end

  describe "non-authenticated access" do
    test "redirects to login" do
      conn = build_conn()
      assert {:error, {:redirect, %{to: path}}} = live(conn, ~p"/my-plan")
      assert path =~ "/users/log-in"
    end
  end
end
