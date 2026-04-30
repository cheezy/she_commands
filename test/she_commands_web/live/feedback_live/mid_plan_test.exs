defmodule SheCommandsWeb.FeedbackLive.MidPlanTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SheCommands.AccountsFixtures
  import SheCommands.FeedbackFixtures
  import SheCommands.PlansFixtures

  alias SheCommands.Feedback

  setup :register_and_log_in_user

  describe "mount" do
    test "renders the prompt question and answer options for the prompt's owner", %{
      conn: conn,
      user: user
    } do
      plan = plan_fixture(%{user: user})
      prompt = feedback_prompt_fixture(%{user: user, plan: plan, prompt_type: :mid_plan})

      {:ok, _view, html} = live(conn, ~p"/feedback/prompts/#{prompt.id}")

      assert html =~ "Was this week doable?"
      assert html =~ "Yes"
      assert html =~ "Somewhat"
      assert html =~ "No"
      assert html =~ "Anything to add"
    end

    test "redirects when accessing another user's prompt", %{conn: conn} do
      stranger = user_fixture(%{})
      plan = plan_fixture(%{user: stranger})
      prompt = feedback_prompt_fixture(%{user: stranger, plan: plan})

      assert {:error, {:redirect, %{to: "/"}}} =
               live(conn, ~p"/feedback/prompts/#{prompt.id}")
    end

    test "renders the already-submitted view for a responded prompt", %{conn: conn, user: user} do
      plan = plan_fixture(%{user: user})
      prompt = feedback_prompt_fixture(%{user: user, plan: plan, prompt_type: :mid_plan})
      {:ok, _} = Feedback.mark_prompt_responded(prompt, "Yes — strong week")

      {:ok, _view, html} = live(conn, ~p"/feedback/prompts/#{prompt.id}")

      assert html =~ "Already submitted"
      assert html =~ "Yes — strong week"
      refute html =~ "phx-submit"
    end
  end

  describe "submit" do
    test "stores the response and shows the thank-you flash", %{conn: conn, user: user} do
      plan = plan_fixture(%{user: user})
      prompt = feedback_prompt_fixture(%{user: user, plan: plan, prompt_type: :mid_plan})

      {:ok, view, _html} = live(conn, ~p"/feedback/prompts/#{prompt.id}")

      html =
        view
        |> form("form", %{answer: "yes", comment: "Felt great"})
        |> render_submit()

      assert html =~ "Thanks for the check-in."
      assert html =~ "Already submitted"

      reloaded = Feedback.get_feedback_prompt!(prompt.id)
      assert reloaded.status == :responded
      assert reloaded.response == "Yes — Felt great"
    end

    test "stores the bare answer when the comment is blank", %{conn: conn, user: user} do
      plan = plan_fixture(%{user: user})
      prompt = feedback_prompt_fixture(%{user: user, plan: plan, prompt_type: :mid_plan})

      {:ok, view, _html} = live(conn, ~p"/feedback/prompts/#{prompt.id}")

      view
      |> form("form", %{answer: "no", comment: "   "})
      |> render_submit()

      reloaded = Feedback.get_feedback_prompt!(prompt.id)
      assert reloaded.response == "No"
    end
  end

  describe "humanize_answer/1" do
    alias SheCommandsWeb.FeedbackLive.MidPlan

    test "humanizes the three answer values" do
      assert MidPlan.humanize_answer("yes") == "Yes"
      assert MidPlan.humanize_answer("no") == "No"
      assert MidPlan.humanize_answer("somewhat") == "Somewhat"
    end
  end
end
