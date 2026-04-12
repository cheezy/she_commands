defmodule SheCommandsWeb.PlanLive.ShowTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SheCommands.ModulesFixtures
  import SheCommands.PlansFixtures

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

  describe "non-authenticated access" do
    test "redirects to login" do
      conn = build_conn()
      assert {:error, {:redirect, %{to: path}}} = live(conn, ~p"/my-plan")
      assert path =~ "/users/log-in"
    end
  end
end
