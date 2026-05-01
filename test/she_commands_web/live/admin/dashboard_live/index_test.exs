defmodule SheCommandsWeb.Admin.DashboardLive.IndexTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  describe "authorization" do
    test "non-admin members are redirected", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin")
    end
  end

  describe "as admin" do
    setup %{user: user} do
      {:ok, _admin} = SheCommands.Accounts.update_user_role(user, :admin)
      :ok
    end

    test "renders the page heading", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin")
      assert html =~ "Administration"
      assert html =~ "Admin"
    end

    test "renders three navigation cards with the correct destinations", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin")

      assert html =~ "Module library"
      assert html =~ "Goal categories"
      assert html =~ "Success metrics"

      assert html =~ ~s|href="/admin/modules"|
      assert html =~ ~s|href="/admin/goal-categories"|
      assert html =~ ~s|href="/admin/metrics"|
    end

    test "renders an icon on each card", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin")
      assert html =~ "hero-rectangle-stack"
      assert html =~ "hero-tag"
      assert html =~ "hero-chart-bar"
    end
  end
end
