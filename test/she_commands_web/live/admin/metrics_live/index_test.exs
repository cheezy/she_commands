defmodule SheCommandsWeb.Admin.MetricsLive.IndexTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SheCommandsWeb.Admin.MetricsLive.Index

  setup :register_and_log_in_user

  describe "authorization" do
    test "redirects member users", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/metrics")
    end
  end

  describe "as admin" do
    setup %{user: user} do
      {:ok, _admin} = SheCommands.Accounts.update_user_role(user, :admin)
      :ok
    end

    test "renders all five metric cards even with no data", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/metrics")

      assert html =~ "Success metrics"
      assert html =~ "Onboarding completion"
      assert html =~ "Module engagement"
      assert html =~ "Plan completion"
      assert html =~ "Post-plan survey completion"
      assert html =~ "Escalation volume"

      # Empty system: every rate is 0% — that's off-target for higher
      # metrics and on-target for the lower-direction escalation metric.
      assert html =~ "0%"
    end
  end

  describe "metric_status/1" do
    test "higher direction is on_target when value meets target" do
      assert Index.metric_status(%{value: 0.5, target: 0.5, direction: :higher}) == :on_target
    end

    test "higher direction is off_target when value is below target" do
      assert Index.metric_status(%{value: 0.49, target: 0.5, direction: :higher}) == :off_target
    end

    test "lower direction is on_target when value is at or below target" do
      assert Index.metric_status(%{value: 0.10, target: 0.25, direction: :lower}) == :on_target
      assert Index.metric_status(%{value: 0.25, target: 0.25, direction: :lower}) == :on_target
    end

    test "lower direction is off_target when value exceeds target" do
      assert Index.metric_status(%{value: 0.50, target: 0.25, direction: :lower}) == :off_target
    end
  end

  describe "percent/1" do
    test "renders rounded integer percentage" do
      assert Index.percent(0.5) == "50%"
      assert Index.percent(0.0) == "0%"
      assert Index.percent(1.0) == "100%"
      assert Index.percent(0.234) == "23%"
    end

    test "non-float falls back to 0%" do
      assert Index.percent(nil) == "0%"
      assert Index.percent(:bogus) == "0%"
    end
  end
end
