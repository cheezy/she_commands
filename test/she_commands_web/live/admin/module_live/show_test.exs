defmodule SheCommandsWeb.Admin.ModuleLive.ShowTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SheCommands.IntakeFixtures
  import SheCommands.ModulesFixtures

  setup :register_and_log_in_user

  describe "non-admin access" do
    test "redirects non-admin users", %{conn: conn} do
      module = module_fixture()
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/modules/#{module.id}")
    end
  end

  describe "admin access" do
    setup %{user: user} do
      user
      |> Ecto.Changeset.change(%{role: :admin})
      |> SheCommands.Repo.update!()

      :ok
    end

    test "renders module details", %{conn: conn} do
      module =
        module_fixture(%{
          title: "Test Detail Module",
          overview: "This is the overview",
          contributor: "Paula V"
        })

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Test Detail Module"
      assert html =~ "This is the overview"
      assert html =~ "Paula V"
    end

    test "shows protocols", %{conn: conn} do
      module = module_fixture()
      protocol_fixture(module, %{position: 1, purpose: "Build core strength"})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Build core strength"
      assert html =~ "Protocol 1"
    end

    test "shows goal categories", %{conn: conn} do
      cat =
        goal_category_fixture(%{
          name: "Test Category",
          slug: "show-test-cat-#{System.unique_integer()}"
        })

      module = module_with_categories_fixture(%{title: "Cat Module"}, [cat])

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Test Category"
    end

    test "shows coach tip with attribution", %{conn: conn} do
      module =
        module_fixture(%{
          coach_tip: "Stay focused and present",
          coach_tip_attribution: "Paula V"
        })

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Stay focused and present"
      assert html =~ "Paula V"
    end

    test "shows missing fields indicator", %{conn: conn} do
      module = module_fixture(%{overview: nil, core_concepts: nil})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Missing Fields"
      assert html =~ "Overview"
      assert html =~ "Core Concepts"
    end

    test "shows back link to module list", %{conn: conn} do
      module = module_fixture()

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Back to modules"
    end
  end
end
