defmodule SheCommandsWeb.Admin.GoalCategoryLive.IndexTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SheCommands.IntakeFixtures

  setup :register_and_log_in_user

  describe "non-admin access" do
    test "redirects non-admin users", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/goal-categories")
    end
  end

  describe "admin access" do
    setup %{user: user} do
      user
      |> Ecto.Changeset.change(%{role: :admin})
      |> SheCommands.Repo.update!()

      :ok
    end

    test "renders every category including hidden ones", %{conn: conn} do
      visible = goal_category_fixture(%{name: "Visible Cat", visible_on_intake: true})
      hidden = goal_category_fixture(%{name: "Hidden Cat", visible_on_intake: false})

      {:ok, _view, html} = live(conn, ~p"/admin/goal-categories")

      assert html =~ "Goal Categories"
      assert html =~ visible.name
      assert html =~ hidden.name
      assert html =~ "Visible"
      assert html =~ "Hidden"
    end

    test "toggle flips visibility from visible to hidden", %{conn: conn} do
      category = goal_category_fixture(%{name: "Toggleable", visible_on_intake: true})

      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories")

      html = render_click(view, "toggle", %{"id" => category.id})

      assert html =~ "Hidden"
      reloaded = SheCommands.Repo.get!(SheCommands.Intake.GoalCategory, category.id)
      assert reloaded.visible_on_intake == false
    end

    test "toggle flips visibility from hidden to visible", %{conn: conn} do
      category = goal_category_fixture(%{name: "Hidden Toggle", visible_on_intake: false})

      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories")
      render_click(view, "toggle", %{"id" => category.id})

      reloaded = SheCommands.Repo.get!(SheCommands.Intake.GoalCategory, category.id)
      assert reloaded.visible_on_intake == true
    end
  end
end
