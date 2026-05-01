defmodule SheCommandsWeb.Admin.ModuleLive.IndexTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SheCommands.IntakeFixtures
  import SheCommands.ModulesFixtures

  setup :register_and_log_in_user

  describe "non-admin access" do
    test "redirects non-admin users", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/modules")
    end
  end

  describe "admin access" do
    setup %{user: user} do
      user
      |> Ecto.Changeset.change(%{role: :admin})
      |> SheCommands.Repo.update!()

      :ok
    end

    test "renders module list", %{conn: conn} do
      module_fixture(%{title: "Test Module Alpha"})

      {:ok, _view, html} = live(conn, ~p"/admin/modules")
      assert html =~ "Module Library"
      assert html =~ "Test Module Alpha"
    end

    test "shows module count", %{conn: conn} do
      module_fixture()
      module_fixture()

      {:ok, _view, html} = live(conn, ~p"/admin/modules")
      assert html =~ "2 modules"
    end

    test "filters by power pillar", %{conn: conn} do
      module_fixture(%{title: "Power Up Mod", power_pillar_1: :power_up})
      module_fixture(%{title: "Power Down Mod", power_pillar_1: :power_down})

      {:ok, view, _html} = live(conn, ~p"/admin/modules")

      html = render_change(view, "filter", %{"power_pillar" => "power_up"})
      assert html =~ "Power Up Mod"
      refute html =~ "Power Down Mod"
    end

    test "filters by goal category", %{conn: conn} do
      cat =
        goal_category_fixture(%{name: "Test Cat", slug: "test-cat-#{System.unique_integer()}"})

      module_with_categories_fixture(%{title: "Cat Module"}, [cat])
      module_fixture(%{title: "No Cat Module"})

      {:ok, view, _html} = live(conn, ~p"/admin/modules")

      html = render_change(view, "filter", %{"goal_category_id" => to_string(cat.id)})
      assert html =~ "Cat Module"
      refute html =~ "No Cat Module"
    end

    test "filters by contributor", %{conn: conn} do
      module_fixture(%{title: "Paula Mod", contributor: "Paula V"})
      module_fixture(%{title: "Andrea Mod", contributor: "Andrea F"})

      {:ok, view, _html} = live(conn, ~p"/admin/modules")

      html = render_change(view, "filter", %{"contributor" => "Paula V"})
      assert html =~ "Paula Mod"
      refute html =~ "Andrea Mod"
    end

    test "clears filters", %{conn: conn} do
      module_fixture(%{title: "Mod A", power_pillar_1: :power_up})
      module_fixture(%{title: "Mod B", power_pillar_1: :power_down})

      {:ok, view, _html} = live(conn, ~p"/admin/modules")

      render_change(view, "filter", %{"power_pillar" => "power_up"})
      html = render_click(view, "clear_filters")

      assert html =~ "Mod A"
      assert html =~ "Mod B"
    end

    test "shows completeness percentage", %{conn: conn} do
      module_fixture(%{
        title: "Complete Module",
        overview: "Overview",
        core_concepts: "Concepts",
        outcomes: "Outcomes",
        modifications: "Mods",
        coach_tip: "Tip",
        intensity: :high,
        daily_time: 30,
        weekly_freq: 3,
        lead_time_fit: :short,
        module_type: :foundational
      })

      {:ok, _view, html} = live(conn, ~p"/admin/modules")
      assert html =~ "100%"
    end

    test "shows empty state when no modules match filters", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/modules")
      assert html =~ "No modules match your filters."
    end
  end

  describe "new action" do
    setup %{user: user} do
      user
      |> Ecto.Changeset.change(%{role: :admin})
      |> SheCommands.Repo.update!()

      :ok
    end

    test "non-admin redirected from /admin/modules/new" do
      member = SheCommands.AccountsFixtures.user_fixture()
      member_conn = Phoenix.ConnTest.build_conn() |> log_in_user(member)

      assert {:error, {:redirect, %{to: "/"}}} = live(member_conn, ~p"/admin/modules/new")
    end

    test "New module button is visible on the index", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/modules")
      assert html =~ "New module"
      assert html =~ ~s|href="/admin/modules/new"|
    end

    test "navigating to /admin/modules/new opens the empty form", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/modules/new")
      assert html =~ "New module"
      assert html =~ "Identity"
    end

    test "valid create persists with selected goal_categories and patches back", %{conn: conn} do
      cat = goal_category_fixture(%{name: "Curated"})
      module_id = "fresh-mod-#{System.unique_integer([:positive])}"

      {:ok, view, _html} = live(conn, ~p"/admin/modules/new")

      view
      |> form("#module-form-form", %{
        module: %{
          module_id: module_id,
          title: "Fresh Module",
          contributor: "Test Contributor",
          power_pillar_1: "power_up",
          intensity: "moderate",
          module_type: "foundational",
          lead_time_fit: "medium",
          goal_category_ids: [Integer.to_string(cat.id)]
        }
      })
      |> render_submit()

      assert_patch(view, ~p"/admin/modules")
      assert render(view) =~ "Fresh Module"

      created = SheCommands.Repo.get_by!(SheCommands.Modules.Module, module_id: module_id)
      reloaded = SheCommands.Repo.preload(created, :goal_categories)
      assert Enum.map(reloaded.goal_categories, & &1.id) == [cat.id]
    end

    test "create with missing required fields shows inline errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/modules/new")

      html =
        view
        |> form("#module-form-form", %{
          module: %{module_id: "", title: "", contributor: ""}
        })
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "edit action" do
    setup %{user: user} do
      user
      |> Ecto.Changeset.change(%{role: :admin})
      |> SheCommands.Repo.update!()

      :ok
    end

    test "non-admin redirected from /admin/modules/:id/edit" do
      member = SheCommands.AccountsFixtures.user_fixture()
      member_conn = Phoenix.ConnTest.build_conn() |> log_in_user(member)
      module = module_fixture(%{title: "Anything"})

      assert {:error, {:redirect, %{to: "/"}}} =
               live(member_conn, ~p"/admin/modules/#{module.id}/edit")
    end

    test "Edit link per row patches to the edit route", %{conn: conn} do
      module = module_fixture(%{title: "Editable"})
      {:ok, _view, html} = live(conn, ~p"/admin/modules")

      assert html =~ ~s|href="/admin/modules/#{module.id}/edit"|
    end

    test "edit form pre-fills the existing module fields", %{conn: conn} do
      module =
        module_fixture(%{title: "Pre-filled", contributor: "Author", module_id: "premod-1"})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}/edit")

      assert html =~ "Edit module"
      assert html =~ ~s|value="Pre-filled"|
      assert html =~ ~s|value="Author"|
      assert html =~ ~s|value="premod-1"|
    end

    test "edit form pre-fills the previously-selected goal_categories", %{conn: conn} do
      cat = goal_category_fixture(%{name: "Selected Cat"})
      module = module_fixture(%{title: "Has Cat"})

      module = module |> SheCommands.Repo.preload(:goal_categories)

      {:ok, _module} =
        SheCommands.Modules.update_module_with_categories(module, %{title: "Has Cat"}, [cat])

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}/edit")

      assert html =~ ~s|value="#{cat.id}" selected|
    end

    test "valid edit persists and the row reflects the new title", %{conn: conn} do
      module = module_fixture(%{title: "Old Title"})

      {:ok, view, _html} = live(conn, ~p"/admin/modules/#{module.id}/edit")

      view
      |> form("#module-form-form", %{
        module: %{
          module_id: module.module_id,
          title: "New Title",
          contributor: module.contributor,
          power_pillar_1: Atom.to_string(module.power_pillar_1)
        }
      })
      |> render_submit()

      assert_patch(view, ~p"/admin/modules")
      assert render(view) =~ "New Title"

      reloaded = SheCommands.Repo.get!(SheCommands.Modules.Module, module.id)
      assert reloaded.title == "New Title"
    end

    test "edit can clear all goal_categories", %{conn: conn} do
      cat = goal_category_fixture(%{name: "ToBeCleared"})
      module = module_fixture(%{title: "WillClear"})
      preloaded = SheCommands.Repo.preload(module, :goal_categories)

      {:ok, module} =
        SheCommands.Modules.update_module_with_categories(
          preloaded,
          %{title: "WillClear"},
          [cat]
        )

      {:ok, view, _html} = live(conn, ~p"/admin/modules/#{module.id}/edit")

      view
      |> form("#module-form-form", %{
        module: %{
          module_id: module.module_id,
          title: module.title,
          contributor: module.contributor,
          power_pillar_1: Atom.to_string(module.power_pillar_1),
          goal_category_ids: []
        }
      })
      |> render_submit()

      reloaded =
        SheCommands.Repo.get!(SheCommands.Modules.Module, module.id)
        |> SheCommands.Repo.preload(:goal_categories)

      assert reloaded.goal_categories == []
    end

    test "Cancel link returns to /admin/modules without saving", %{conn: conn} do
      module = module_fixture(%{title: "Untouched"})

      {:ok, view, _html} = live(conn, ~p"/admin/modules/#{module.id}/edit")
      view |> element("a", "Cancel") |> render_click()
      assert_patch(view, ~p"/admin/modules")

      reloaded = SheCommands.Repo.get!(SheCommands.Modules.Module, module.id)
      assert reloaded.title == "Untouched"
    end
  end
end
