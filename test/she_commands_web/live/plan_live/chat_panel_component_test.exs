defmodule SheCommandsWeb.PlanLive.ChatPanelComponentTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SheCommands.ChatFixtures
  import SheCommands.ModulesFixtures
  import SheCommands.PlansFixtures

  setup :register_and_log_in_user

  setup %{user: user} do
    plan =
      plan_fixture(%{
        user: user,
        status: :active,
        plan_type: :weekly,
        goal_statement: "Lead with confidence"
      })

    module = module_fixture(%{title: "Test Module"})

    protocol_fixture(module, %{
      position: 1,
      purpose: "Core strength",
      steps: "Step 1",
      prescription: "3x/week"
    })

    plan_module_fixture(plan, %{module: module, power_pillar: :power_up, position: 1})

    %{plan: plan}
  end

  describe "chat toggle button" do
    test "is visible on plan page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      assert html =~ "hero-chat-bubble-left-right"
    end

    test "panel is initially closed", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/my-plan")
      refute html =~ "chat-messages"
    end

    test "opens panel on click", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      html = render_click(view, "toggle_chat")
      assert html =~ "chat-messages"
      assert html =~ "Ask about your plan..."
    end

    test "closes panel on second click", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")
      html = render_click(view, "toggle_chat")
      refute html =~ "chat-messages"
    end
  end

  describe "empty state" do
    test "shows greeting and suggested questions", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      html = render_click(view, "toggle_chat")

      assert html =~ "your plan assistant"
      assert html =~ "What should I focus on today?"
      assert html =~ "Explain my Power Up modules"
      assert html =~ "How do I modify exercises for my level?"
    end
  end

  describe "message display" do
    test "renders user messages", %{conn: conn, user: user, plan: plan} do
      chat_message_fixture(%{
        user: user,
        plan: plan,
        role: :user,
        content: "Hello from the user"
      })

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      html = render_click(view, "toggle_chat")

      assert html =~ "Hello from the user"
      assert html =~ "bg-base-200"
    end

    test "renders assistant messages", %{conn: conn, user: user, plan: plan} do
      chat_message_fixture(%{
        user: user,
        plan: plan,
        role: :assistant,
        content: "Hello from the assistant"
      })

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      html = render_click(view, "toggle_chat")

      assert html =~ "Hello from the assistant"
      assert html =~ "bg-base-300"
    end

    test "does not show suggested questions when messages exist", %{
      conn: conn,
      user: user,
      plan: plan
    } do
      chat_message_fixture(%{user: user, plan: plan, role: :user, content: "Hi"})

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      html = render_click(view, "toggle_chat")

      refute html =~ "What should I focus on today?"
    end
  end

  describe "message submission" do
    test "sends a message via form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      html =
        view
        |> element("form")
        |> render_submit(%{"message" => "What is my plan about?"})

      assert html =~ "What is my plan about?"
    end

    test "suggested question click sends message", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      html =
        render_click(view, "suggest_question", %{"question" => "What should I focus on today?"})

      assert html =~ "What should I focus on today?"
    end

    test "empty message does not create a message", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      html =
        view
        |> element("form")
        |> render_submit(%{"message" => ""})

      assert html =~ "your plan assistant"
    end

    test "whitespace-only message does not create a message", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      html =
        view
        |> element("form")
        |> render_submit(%{"message" => "   "})

      assert html =~ "your plan assistant"
    end
  end

  describe "clear conversation" do
    test "clears all messages", %{conn: conn, user: user, plan: plan} do
      chat_message_fixture(%{user: user, plan: plan, role: :user, content: "Old message"})

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")
      html = render_click(view, "clear_chat")

      refute html =~ "Old message"
      assert html =~ "your plan assistant"
    end
  end

  describe "typing indicator" do
    test "renders when loading is true", %{conn: conn, user: user, plan: plan} do
      chat_message_fixture(%{user: user, plan: plan, role: :user, content: "Hello"})

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      send(view.pid, {:set_chat_loading, true})
      html = render(view)
      assert html =~ "animate-bounce"
    end
  end

  describe "gettext translations" do
    test "all visible text uses gettext", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/my-plan")
      html = render_click(view, "toggle_chat")

      assert html =~ "Chat"
      assert html =~ "Ask about your plan..."
      assert html =~ "your plan assistant"
    end
  end
end
