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
      assert html =~ "border-primary"
    end
  end

  describe "option selection" do
    test "selecting lead time updates the response", %{conn: conn, user: user} do
      _category = goal_category_fixture()
      intake_response_fixture(user, %{current_step: 3})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{"field" => "lead_time", "value" => "short"})

      assert html =~ "border-primary"
    end

    test "selecting hours_per_day updates the response", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 4})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{
          "field" => "hours_per_day",
          "value" => "thirty_to_sixty"
        })

      assert html =~ "border-primary"
    end

    test "selecting intensity updates the response", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 4})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{"field" => "intensity", "value" => "high"})

      assert html =~ "border-primary"
    end

    test "selecting coaching_preference updates the response", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 6})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{
          "field" => "coaching_preference",
          "value" => "coach_guided"
        })

      assert html =~ "border-primary"
    end

    test "selecting fitness_regimen updates the response", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 7})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{
          "field" => "fitness_regimen",
          "value" => "moderate"
        })

      assert html =~ "border-primary"
    end

    test "selecting personal_dev_regimen updates the response", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 7})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{
          "field" => "personal_dev_regimen",
          "value" => "active"
        })

      assert html =~ "border-primary"
    end

    test "selecting unknown field is a no-op", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 4})

      {:ok, view, _html} = live(conn, ~p"/intake")

      html =
        render_click(view, "select_option", %{"field" => "unknown_field", "value" => "foo"})

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
      html = render_click(view, "toggle_limitation", %{"value" => "menopause"})
      assert html =~ "border-primary"
    end

    test "toggling a selected limitation deselects it", %{conn: conn, user: user} do
      intake_response_fixture(user, %{current_step: 5, limitations: ["menopause"]})

      {:ok, view, _html} = live(conn, ~p"/intake")
      html = render_click(view, "toggle_limitation", %{"value" => "menopause"})

      refute html =~
               "border-primary bg-primary/10\" >\n      <span class=\"text-base-content\">Menopause"
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

      assert html =~ "complete all required fields"
    end
  end
end
