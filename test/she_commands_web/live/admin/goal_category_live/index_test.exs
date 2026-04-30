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

    test "renders the page title in the document head", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/goal-categories")
      assert html =~ "Goal Categories"
      assert html =~ "Administration"
    end

    test "renders the category count", %{conn: conn} do
      goal_category_fixture(%{name: "Cat A"})
      goal_category_fixture(%{name: "Cat B"})
      goal_category_fixture(%{name: "Cat C"})

      {:ok, _view, html} = live(conn, ~p"/admin/goal-categories")
      assert html =~ "3 categories"
    end

    test "renders zero count when no categories exist", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/goal-categories")
      assert html =~ "0 categories"
    end

    test "renders categories in position order", %{conn: conn} do
      late = goal_category_fixture(%{name: "ZZZ Late", position: 9})
      early = goal_category_fixture(%{name: "AAA Early", position: 1})

      {:ok, _view, html} = live(conn, ~p"/admin/goal-categories")

      early_index = :binary.match(html, early.name) |> elem(0)
      late_index = :binary.match(html, late.name) |> elem(0)
      assert early_index < late_index
    end

    test "renders the slug and position of each category", %{conn: conn} do
      category =
        goal_category_fixture(%{
          name: "With Slug",
          slug: "specific-slug-#{System.unique_integer([:positive])}",
          position: 7
        })

      {:ok, _view, html} = live(conn, ~p"/admin/goal-categories")

      assert html =~ category.slug
      assert html =~ ">7</td>"
    end

    test "shows Hide action label for visible categories", %{conn: conn} do
      goal_category_fixture(%{name: "Showing", visible_on_intake: true})

      {:ok, _view, html} = live(conn, ~p"/admin/goal-categories")
      assert html =~ "Hide"
    end

    test "shows Show action label for hidden categories", %{conn: conn} do
      goal_category_fixture(%{name: "Concealed", visible_on_intake: false})

      {:ok, _view, html} = live(conn, ~p"/admin/goal-categories")
      assert html =~ "Show"
    end

    test "toggle does not affect other categories", %{conn: conn} do
      target = goal_category_fixture(%{name: "Target", visible_on_intake: true})
      bystander = goal_category_fixture(%{name: "Bystander", visible_on_intake: true})
      already_hidden = goal_category_fixture(%{name: "AlreadyHidden", visible_on_intake: false})

      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories")
      render_click(view, "toggle", %{"id" => target.id})

      assert SheCommands.Repo.get!(SheCommands.Intake.GoalCategory, target.id).visible_on_intake ==
               false

      assert SheCommands.Repo.get!(
               SheCommands.Intake.GoalCategory,
               bystander.id
             ).visible_on_intake == true

      assert SheCommands.Repo.get!(
               SheCommands.Intake.GoalCategory,
               already_hidden.id
             ).visible_on_intake == false
    end

    test "toggling twice returns the category to the original state", %{conn: conn} do
      category = goal_category_fixture(%{name: "RoundTrip", visible_on_intake: true})

      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories")
      render_click(view, "toggle", %{"id" => category.id})
      render_click(view, "toggle", %{"id" => category.id})

      reloaded = SheCommands.Repo.get!(SheCommands.Intake.GoalCategory, category.id)
      assert reloaded.visible_on_intake == true
    end

    test "after toggle the row reflects the new status badge", %{conn: conn} do
      category = goal_category_fixture(%{name: "BadgeCheck", visible_on_intake: true})

      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories")
      html_after = render_click(view, "toggle", %{"id" => category.id})

      # The row for BadgeCheck now shows the Hidden badge and a Show action
      assert html_after =~ "BadgeCheck"
      assert html_after =~ "Hidden"
      assert html_after =~ "Show"
    end
  end
end
