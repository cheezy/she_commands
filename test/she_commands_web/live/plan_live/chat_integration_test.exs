defmodule SheCommandsWeb.PlanLive.ChatIntegrationTest do
  @moduledoc """
  Integration tests for the chat AI flow in the plan view.

  These tests are async: false because the Task.Supervisor.async_nolink
  used for non-blocking API calls requires Req.Test ownership propagation
  that is not compatible with async test isolation.
  """
  use SheCommandsWeb.ConnCase, async: false

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
        goal_statement: "Lead with confidence in every room",
        expected_outcomes: "Power Up: Fuel energy"
      })

    module = module_fixture(%{title: "Test Module"})

    protocol_fixture(module, %{
      position: 1,
      purpose: "Build core strength",
      steps: "Step 1",
      prescription: "3x/week"
    })

    plan_module_fixture(plan, %{module: module, power_pillar: :power_up, position: 1})

    %{plan: plan}
  end

  describe "AI response flow" do
    test "sends message and receives AI response", %{conn: conn} do
      Req.Test.stub(SheCommands.Chat.ClaudeClient, fn conn ->
        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "Here is your coaching advice."}]
        })
      end)

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      view
      |> element("form")
      |> render_submit(%{"message" => "Help me with my plan"})

      wait_for_chat_to_settle(view)
      html = render(view)

      assert html =~ "Help me with my plan"
      assert html =~ "Here is your coaching advice."
    end

    test "shows loading indicator during API call", %{conn: conn} do
      Req.Test.stub(SheCommands.Chat.ClaudeClient, fn conn ->
        Process.sleep(500)

        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "Response"}]
        })
      end)

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      view
      |> element("form")
      |> render_submit(%{"message" => "Hello"})

      html = render(view)
      assert html =~ "animate-bounce"

      wait_for_chat_to_settle(view)
    end

    test "shows error state on API failure", %{conn: conn} do
      Req.Test.stub(SheCommands.Chat.ClaudeClient, fn conn ->
        conn
        |> Plug.Conn.put_status(500)
        |> Req.Test.json(%{"error" => %{"message" => "Server error"}})
      end)

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      view
      |> element("form")
      |> render_submit(%{"message" => "Hello"})

      wait_for_chat_to_settle(view)
      html = render(view)

      assert html =~ "Something went wrong"
      assert html =~ "Retry"
    end

    test "retry sends message again after error", %{conn: conn} do
      {:ok, counter} = Agent.start_link(fn -> 0 end)

      Req.Test.stub(SheCommands.Chat.ClaudeClient, fn conn ->
        call = Agent.get_and_update(counter, fn n -> {n, n + 1} end)

        if call == 0 do
          conn
          |> Plug.Conn.put_status(500)
          |> Req.Test.json(%{"error" => %{"message" => "fail"}})
        else
          Req.Test.json(conn, %{
            "content" => [%{"type" => "text", "text" => "Success after retry!"}]
          })
        end
      end)

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      # First send fails
      view |> element("form") |> render_submit(%{"message" => "Hello"})
      wait_for_chat_to_settle(view)
      html = render(view)
      assert html =~ "Something went wrong"

      # Retry succeeds
      render_click(view, "retry_message")
      wait_for_chat_to_settle(view)
      html = render(view)
      assert html =~ "Success after retry!"
    end

    test "blocks rapid sending while loading", %{conn: conn} do
      Req.Test.stub(SheCommands.Chat.ClaudeClient, fn conn ->
        Process.sleep(1000)

        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "Response"}]
        })
      end)

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      view |> element("form") |> render_submit(%{"message" => "First"})
      view |> element("form") |> render_submit(%{"message" => "Second"})

      html = render(view)
      assert html =~ "First"
      refute html =~ "Second"

      wait_for_chat_to_settle(view)
    end

    test "RAG context includes user plan data", %{conn: conn} do
      test_pid = self()

      Req.Test.stub(SheCommands.Chat.ClaudeClient, fn conn ->
        body = Plug.Conn.read_body(conn) |> elem(1) |> Jason.decode!()
        send(test_pid, {:system_prompt, body["system"]})

        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "Response"}]
        })
      end)

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      view |> element("form") |> render_submit(%{"message" => "Hello"})

      assert_receive {:system_prompt, system_prompt}, 1000
      assert system_prompt =~ "Lead with confidence"
      assert system_prompt =~ "Test Module"

      wait_for_chat_to_settle(view)
    end

    test "shows error state on API timeout", %{conn: conn} do
      Req.Test.stub(SheCommands.Chat.ClaudeClient, fn conn ->
        Req.Test.transport_error(conn, :timeout)
      end)

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      render_click(view, "toggle_chat")

      view |> element("form") |> render_submit(%{"message" => "Hello"})
      wait_for_chat_to_settle(view)
      html = render(view)

      assert html =~ "Something went wrong"
      assert html =~ "Retry"
    end

    test "conversation persists across remounts", %{conn: conn, user: user, plan: plan} do
      chat_message_fixture(%{user: user, plan: plan, role: :user, content: "Persisted question"})

      chat_message_fixture(%{
        user: user,
        plan: plan,
        role: :assistant,
        content: "Persisted answer"
      })

      {:ok, view, _html} = live(conn, ~p"/my-plan")
      html = render_click(view, "toggle_chat")

      assert html =~ "Persisted question"
      assert html =~ "Persisted answer"
    end
  end

  defp wait_for_chat_to_settle(view, timeout \\ 2_000) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_wait_for_chat_to_settle(view, deadline)
  end

  defp do_wait_for_chat_to_settle(view, deadline) do
    cond do
      not Process.alive?(view.pid) ->
        :ok

      not (render(view) =~ "animate-bounce") ->
        :ok

      System.monotonic_time(:millisecond) >= deadline ->
        :timeout

      true ->
        Process.sleep(50)
        do_wait_for_chat_to_settle(view, deadline)
    end
  end
end
