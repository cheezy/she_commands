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
end
