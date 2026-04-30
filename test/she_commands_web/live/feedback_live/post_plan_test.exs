defmodule SheCommandsWeb.FeedbackLive.PostPlanTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SheCommands.AccountsFixtures
  import SheCommands.FeedbackFixtures
  import SheCommands.PlansFixtures

  alias SheCommands.Feedback

  setup :register_and_log_in_user

  describe "mount" do
    test "renders the three survey questions for the survey's owner", %{conn: conn, user: user} do
      plan = plan_fixture(%{user: user})
      survey = feedback_survey_fixture(%{user: user, plan: plan, survey_type: :post_plan_review})

      {:ok, _view, html} = live(conn, ~p"/feedback/surveys/#{survey.id}")

      assert html =~ "How did your plan go?"
      assert html =~ "What changed?"
      assert html =~ "What was hardest?"
      assert html =~ "What do you want next?"
    end

    test "redirects when accessing another user's survey", %{conn: conn} do
      stranger = user_fixture(%{})
      plan = plan_fixture(%{user: stranger})
      survey = feedback_survey_fixture(%{user: stranger, plan: plan})

      assert {:error, {:redirect, %{to: "/"}}} =
               live(conn, ~p"/feedback/surveys/#{survey.id}")
    end

    test "renders the read-only view when already completed", %{conn: conn, user: user} do
      plan = plan_fixture(%{user: user})
      survey = feedback_survey_fixture(%{user: user, plan: plan})

      {:ok, _} =
        Feedback.complete_survey(survey, %{
          "what_changed" => "Energy is up",
          "what_was_hardest" => "Mornings",
          "what_do_you_want_next" => "More accountability"
        })

      {:ok, _view, html} = live(conn, ~p"/feedback/surveys/#{survey.id}")

      assert html =~ "Already submitted"
      assert html =~ "Energy is up"
      assert html =~ "Mornings"
      assert html =~ "More accountability"
    end
  end

  describe "submit" do
    test "stores responses and shows the thank-you state", %{conn: conn, user: user} do
      plan = plan_fixture(%{user: user})
      survey = feedback_survey_fixture(%{user: user, plan: plan})

      {:ok, view, _html} = live(conn, ~p"/feedback/surveys/#{survey.id}")

      html =
        view
        |> form("form", %{
          what_changed: "More clarity",
          what_was_hardest: "Time",
          what_do_you_want_next: "Sharper focus"
        })
        |> render_submit()

      assert html =~ "Thanks for the feedback."
      assert html =~ "More clarity"
      assert html =~ "Already submitted"

      reloaded = Feedback.get_feedback_survey!(survey.id)
      assert reloaded.completed_at
      assert reloaded.responses == %{
               "what_changed" => "More clarity",
               "what_was_hardest" => "Time",
               "what_do_you_want_next" => "Sharper focus"
             }
    end

    test "blocks submission when all three answers are blank", %{conn: conn, user: user} do
      plan = plan_fixture(%{user: user})
      survey = feedback_survey_fixture(%{user: user, plan: plan})

      {:ok, view, _html} = live(conn, ~p"/feedback/surveys/#{survey.id}")

      html =
        view
        |> form("form", %{
          what_changed: "   ",
          what_was_hardest: "",
          what_do_you_want_next: "  "
        })
        |> render_submit()

      assert html =~ "Please answer at least one question."

      reloaded = Feedback.get_feedback_survey!(survey.id)
      refute reloaded.completed_at
    end

    test "accepts a partial answer", %{conn: conn, user: user} do
      plan = plan_fixture(%{user: user})
      survey = feedback_survey_fixture(%{user: user, plan: plan})

      {:ok, view, _html} = live(conn, ~p"/feedback/surveys/#{survey.id}")

      view
      |> form("form", %{
        what_changed: "",
        what_was_hardest: "Sleep schedule",
        what_do_you_want_next: ""
      })
      |> render_submit()

      reloaded = Feedback.get_feedback_survey!(survey.id)

      assert reloaded.responses == %{
               "what_changed" => "",
               "what_was_hardest" => "Sleep schedule",
               "what_do_you_want_next" => ""
             }

      assert reloaded.completed_at
    end
  end
end
