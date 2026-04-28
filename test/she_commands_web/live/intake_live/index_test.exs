defmodule SheCommandsWeb.IntakeLive.IndexTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SheCommands.IntakeFixtures

  setup :register_and_log_in_user

  describe "mount" do
    test "renders the first step", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/intake")
      assert html =~ "What&#39;s your goal?"
      assert html =~ "Step 1 of 8"
    end

    test "redirects if not logged in" do
      conn = build_conn()
      assert {:error, redirect} = live(conn, ~p"/intake")
      assert {:redirect, %{to: path}} = redirect
      assert path =~ "/users/log-in"
    end

    test "resumes from saved step", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 3, lead_time: :short})

      {:ok, _view, html} = live(conn, ~p"/intake")
      assert html =~ "Step 3 of 8"
    end
  end

  describe "step navigation" do
    test "advances to next step", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        view
        |> form("form", %{goal_intent: "I want to lead with confidence"})
        |> render_submit()

      assert html =~ "Which area resonates most?"
      assert html =~ "Step 2 of 8"
    end

    test "goes back to previous step", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 3})

      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_click(view, "back")
      assert html =~ "Step 2 of 8"
    end

    test "cannot go back from step 1", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_click(view, "back")
      assert html =~ "Step 1 of 8"
    end
  end

  describe "goal category selection" do
    test "selecting a category highlights it", %{conn: conn, user: user} do
      category = goal_category_fixture()
      intake_response_fixture(user, %{current_step: 2})

      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_click(view, "select_category", %{"id" => category.id})
      assert html =~ "border-base-content bg-base-content/5"
    end
  end

  describe "option selection" do
    test "selecting lead time updates the response", %{conn: conn, user: user} do
      _category = goal_category_fixture()
      intake_response_fixture(user, %{current_step: 3})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{"field" => "lead_time", "option" => "short"})

      assert html =~ "border-base-content bg-base-content/5"
    end

    test "selecting hours_per_day updates the response", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 4})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{
          "field" => "hours_per_day",
          "option" => "thirty_to_sixty"
        })

      assert html =~ "border-base-content bg-base-content/5"
    end

    test "selecting intensity updates the response", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 4})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{"field" => "intensity", "option" => "high"})

      assert html =~ "border-base-content bg-base-content/5"
    end

    test "selecting coaching_preference updates the response", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 6})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{
          "field" => "coaching_preference",
          "option" => "coach_guided"
        })

      assert html =~ "border-base-content bg-base-content/5"
    end

    test "selecting fitness_regimen updates the response", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 7})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{
          "field" => "fitness_regimen",
          "option" => "moderate"
        })

      assert html =~ "border-base-content bg-base-content/5"
    end

    test "selecting personal_dev_regimen updates the response", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 7})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{
          "field" => "personal_dev_regimen",
          "option" => "active"
        })

      assert html =~ "border-base-content bg-base-content/5"
    end

    test "selecting unknown field is a no-op", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 4})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{"field" => "unknown_field", "option" => "foo"})

      # Should not crash, still on step 4
      assert html =~ "Step 4 of 8"
    end
  end

  describe "days per week" do
    test "updating days updates the response", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 4})

      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_change(view, "update_days", %{"days" => "5"})
      assert html =~ "5"
    end
  end

  describe "days per week - edge cases" do
    test "ignores invalid days value", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 4, days_per_week: 3})

      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_change(view, "update_days", %{"days" => "invalid"})
      # Should not crash, stays on step 4
      assert html =~ "Step 4 of 8"
    end

    test "ignores out-of-range days value", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 4, days_per_week: 3})

      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_change(view, "update_days", %{"days" => "10"})
      assert html =~ "Step 4 of 8"
    end
  end

  describe "step save on navigation" do
    test "saves limitations_notes when advancing from step 5", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 5})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        view
        |> form("form", %{limitations_notes: "Bad knees from running"})
        |> render_submit()

      assert html =~ "Step 6 of 8"
    end

    test "saves regimen notes when advancing from step 7", %{conn: conn, user: user} do
      intake_response_fixture(user, %{
        current_step: 7,
        fitness_regimen_notes: "Yoga 3x/week",
        personal_dev_regimen_notes: "Podcasts daily"
      })

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        view
        |> form("form")
        |> render_submit()

      assert html =~ "Step 8 of 8"
    end
  end

  describe "limitations" do
    test "toggling a limitation selects it", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 5})

      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_click(view, "toggle_limitation", %{"option" => "menopause"})
      assert html =~ "border-base-content bg-base-content/5"
    end

    test "toggling a selected limitation deselects it", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 5, limitations: ["menopause"]})

      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_click(view, "toggle_limitation", %{"option" => "menopause"})

      refute html =~
               "border-base-content bg-base-content/5\"><span class=\"text-sm text-base-content\">Menopause"
    end
  end

  describe "completion" do
    test "completing with all required fields succeeds", %{conn: conn, user: user} do
      category = goal_category_fixture()

      intake_response_fixture(user, %{
        current_step: 8,
        goal_intent: "My goal",
        goal_category_id: category.id,
        lead_time: :short,
        days_per_week: 3,
        hours_per_day: :thirty_to_sixty,
        intensity: :moderate
      })

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        view
        |> form("form", %{
          city: "Toronto",
          province: "Ontario",
          country: "Canada"
        })
        |> render_submit()

      assert html =~ "You&#39;re all set."
    end

    test "completing with missing required fields shows error", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 8})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        view
        |> form("form", %{city: "Toronto"})
        |> render_submit()

      assert html =~ "Please complete the following before continuing"
      # Earlier-step required fields are surfaced by name
      assert html =~ "Goal"
      assert html =~ "Focus area"
      assert html =~ "Timeline"
    end
  end

  describe "step-level validation" do
    test "advancing from step 1 with empty goal_intent shows error and stays on step 1",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        view
        |> form("form", %{goal_intent: ""})
        |> render_submit()

      assert html =~ "Please complete the following before continuing"
      assert html =~ "Goal"
      assert html =~ "Step 1 of 8"
    end

    test "advancing from step 1 with whitespace-only goal_intent shows error",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        view
        |> form("form", %{goal_intent: "   "})
        |> render_submit()

      assert html =~ "Please complete the following before continuing"
      assert html =~ "Step 1 of 8"
    end

    test "advancing from step 2 without selecting a category shows error",
         %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 2, goal_intent: "My goal"})

      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_click(view, "next")

      assert html =~ "Please complete the following before continuing"
      assert html =~ "Focus area"
      assert html =~ "Step 2 of 8"
    end

    test "advancing from step 3 without selecting a lead time shows error",
         %{conn: conn, user: user} do
      category = goal_category_fixture()

      intake_response_fixture(user, %{
        current_step: 3,
        goal_intent: "My goal",
        goal_category_id: category.id
      })

      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_click(view, "next")

      assert html =~ "Please complete the following before continuing"
      assert html =~ "Timeline"
      assert html =~ "Step 3 of 8"
    end

    test "advancing from step 4 without hours_per_day or intensity shows error",
         %{conn: conn, user: user} do
      category = goal_category_fixture()

      intake_response_fixture(user, %{
        current_step: 4,
        goal_intent: "My goal",
        goal_category_id: category.id,
        lead_time: :short
      })

      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_click(view, "next")

      assert html =~ "Please complete the following before continuing"
      assert html =~ "Time per session"
      assert html =~ "Intensity"
      assert html =~ "Step 4 of 8"
    end

    test "advancing from step 4 with all availability fields succeeds",
         %{conn: conn, user: user} do
      category = goal_category_fixture()

      intake_response_fixture(user, %{
        current_step: 4,
        goal_intent: "My goal",
        goal_category_id: category.id,
        lead_time: :short,
        days_per_week: 3,
        hours_per_day: :thirty_to_sixty,
        intensity: :moderate
      })

      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_click(view, "next")

      assert html =~ "Step 5 of 8"
    end

    test "step 4 defaults days_per_week to 3 when user advances without moving slider",
         %{conn: conn, user: user} do
      category = goal_category_fixture()

      response =
        intake_response_fixture(user, %{
          current_step: 4,
          goal_intent: "My goal",
          goal_category_id: category.id,
          lead_time: :short,
          hours_per_day: :thirty_to_sixty,
          intensity: :moderate
        })

      assert is_nil(response.days_per_week)

      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_click(view, "next")

      assert html =~ "Step 5 of 8"

      reloaded = SheCommands.Repo.get!(SheCommands.Intake.IntakeResponse, response.id)
      assert reloaded.days_per_week == 3
    end

    test "steps without required fields advance freely", %{conn: conn, user: user} do
      category = goal_category_fixture()

      intake_response_fixture(user, %{
        current_step: 5,
        goal_intent: "My goal",
        goal_category_id: category.id,
        lead_time: :short,
        days_per_week: 3,
        hours_per_day: :thirty_to_sixty,
        intensity: :moderate
      })

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        view
        |> form("form", %{limitations_notes: ""})
        |> render_submit()

      assert html =~ "Step 6 of 8"
    end
  end
end
