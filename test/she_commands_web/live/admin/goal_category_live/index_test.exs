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

  describe "edit action" do
    setup %{user: user} do
      user
      |> Ecto.Changeset.change(%{role: :admin})
      |> SheCommands.Repo.update!()

      :ok
    end

    test "non-admin redirected from /admin/goal-categories/:id/edit" do
      # Use a freshly registered member (the describe-block setup promoted
      # the conn user to admin; we need a clean member-only session here).
      member = SheCommands.AccountsFixtures.user_fixture()
      member_conn = Phoenix.ConnTest.build_conn() |> log_in_user(member)
      category = goal_category_fixture(%{name: "Anything"})

      assert {:error, {:redirect, %{to: "/"}}} =
               live(member_conn, ~p"/admin/goal-categories/#{category.id}/edit")
    end

    test "navigating to the edit route renders the form pre-filled", %{conn: conn} do
      category =
        goal_category_fixture(%{
          name: "Editable",
          slug: "editable-cat",
          description: "Old description"
        })

      {:ok, _view, html} = live(conn, ~p"/admin/goal-categories/#{category.id}/edit")

      assert html =~ "Edit goal category"
      assert html =~ ~s|value="Editable"|
      assert html =~ ~s|value="editable-cat"|
      assert html =~ "Old description"
    end

    test "valid edit persists and patches back to the index", %{conn: conn} do
      category = goal_category_fixture(%{name: "Old Name", slug: "old-slug"})

      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories")

      view |> element(~s|a[href="/admin/goal-categories/#{category.id}/edit"]|) |> render_click()

      assert_patch(view, ~p"/admin/goal-categories/#{category.id}/edit")

      view
      |> form("#goal-category-form-form",
        goal_category: %{name: "New Name", slug: "old-slug"}
      )
      |> render_submit()

      assert_patch(view, ~p"/admin/goal-categories")

      assert render(view) =~ "New Name"

      reloaded = SheCommands.Repo.get!(SheCommands.Intake.GoalCategory, category.id)
      assert reloaded.name == "New Name"
    end

    test "edit with invalid attrs surfaces an inline error", %{conn: conn} do
      category = goal_category_fixture(%{name: "Existing"})

      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories/#{category.id}/edit")

      html =
        view
        |> form("#goal-category-form-form",
          goal_category: %{name: "", slug: ""}
        )
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "edit with name longer than 200 chars rejects", %{conn: conn} do
      category = goal_category_fixture(%{})
      long_name = String.duplicate("a", 201)

      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories/#{category.id}/edit")

      html =
        view
        |> form("#goal-category-form-form",
          goal_category: %{name: long_name, slug: category.slug}
        )
        |> render_submit()

      assert html =~ "should be at most 200"
    end

    test "edit with a colliding slug rejects", %{conn: conn} do
      _other = goal_category_fixture(%{slug: "taken-slug"})
      target = goal_category_fixture(%{slug: "mine-slug"})

      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories/#{target.id}/edit")

      html =
        view
        |> form("#goal-category-form-form",
          goal_category: %{name: target.name, slug: "taken-slug"}
        )
        |> render_submit()

      assert html =~ "has already been taken"
    end

    test "Cancel link patches back to the index without saving", %{conn: conn} do
      category = goal_category_fixture(%{name: "Untouched"})

      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories/#{category.id}/edit")

      view |> element("a", "Cancel") |> render_click()
      assert_patch(view, ~p"/admin/goal-categories")

      reloaded = SheCommands.Repo.get!(SheCommands.Intake.GoalCategory, category.id)
      assert reloaded.name == "Untouched"
    end

    test "visible_on_intake checkbox change persists", %{conn: conn} do
      category = goal_category_fixture(%{visible_on_intake: true})

      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories/#{category.id}/edit")

      view
      |> form("#goal-category-form-form",
        goal_category: %{
          name: category.name,
          slug: category.slug,
          visible_on_intake: "false"
        }
      )
      |> render_submit()

      reloaded = SheCommands.Repo.get!(SheCommands.Intake.GoalCategory, category.id)
      assert reloaded.visible_on_intake == false
    end
  end

  describe "new action" do
    setup %{user: user} do
      user
      |> Ecto.Changeset.change(%{role: :admin})
      |> SheCommands.Repo.update!()

      :ok
    end

    test "non-admin redirected from /admin/goal-categories/new" do
      member = SheCommands.AccountsFixtures.user_fixture()
      member_conn = Phoenix.ConnTest.build_conn() |> log_in_user(member)

      assert {:error, {:redirect, %{to: "/"}}} =
               live(member_conn, ~p"/admin/goal-categories/new")
    end

    test "New category button is rendered on the index", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/goal-categories")
      assert html =~ "New category"
      assert html =~ ~s|href="/admin/goal-categories/new"|
    end

    test "navigating to /admin/goal-categories/new opens the empty form", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/goal-categories/new")
      assert html =~ "New goal category"
    end

    test "valid create persists and patches back to the index", %{conn: conn} do
      slug = "fresh-cat-#{System.unique_integer([:positive])}"

      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories")

      view |> element(~s|a[href="/admin/goal-categories/new"]|) |> render_click()
      assert_patch(view, ~p"/admin/goal-categories/new")

      view
      |> form("#goal-category-form-form",
        goal_category: %{name: "Fresh Category", slug: slug}
      )
      |> render_submit()

      assert_patch(view, ~p"/admin/goal-categories")
      assert render(view) =~ "Fresh Category"

      created = SheCommands.Repo.get_by!(SheCommands.Intake.GoalCategory, slug: slug)
      assert created.name == "Fresh Category"
    end

    test "create with no name surfaces a required-field error", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories/new")

      html =
        view
        |> form("#goal-category-form-form", goal_category: %{name: "", slug: "anything"})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "create with a duplicate slug rejects", %{conn: conn} do
      goal_category_fixture(%{slug: "already-here"})

      {:ok, view, _html} = live(conn, ~p"/admin/goal-categories/new")

      html =
        view
        |> form("#goal-category-form-form",
          goal_category: %{name: "Doomed", slug: "already-here"}
        )
        |> render_submit()

      assert html =~ "has already been taken"
    end
  end
end
