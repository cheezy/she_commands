defmodule SheCommandsWeb.PlanControllerTest do
  use SheCommandsWeb.ConnCase, async: true

  import SheCommands.ModulesFixtures
  import SheCommands.PlansFixtures

  setup :register_and_log_in_user

  describe "print" do
    test "renders printable plan view", %{conn: conn, user: user} do
      plan =
        plan_fixture(%{
          user: user,
          status: :active,
          goal_statement: "Lead with confidence",
          expected_outcomes: "Power Up: Energy"
        })

      module = module_fixture(%{title: "Test Module"})
      protocol_fixture(module, %{position: 1, purpose: "Build strength"})
      plan_module_fixture(plan, %{module: module, position: 1})

      conn = get(conn, ~p"/plans/#{plan.id}/print")
      assert html_response(conn, 200) =~ "Lead with confidence"
      assert html_response(conn, 200) =~ "Test Module"
      assert html_response(conn, 200) =~ "Build strength"
      assert html_response(conn, 200) =~ "Print / Save as PDF"
    end

    test "blocks access to other user's plan", %{conn: conn} do
      other_plan = plan_fixture(%{status: :active})

      conn = get(conn, ~p"/plans/#{other_plan.id}/print")
      assert redirected_to(conn) == "/"
    end
  end
end
