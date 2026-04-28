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

    test "raises when the module does not exist", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/admin/modules/999999")
      end
    end

    test "sets the page title from the module title", %{conn: conn} do
      module = module_fixture(%{title: "Distinct Page Title"})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Distinct Page Title"
    end

    test "renders multi-word power pillar names with capitalization", %{conn: conn} do
      module = module_fixture(%{power_pillar_1: :power_through})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Power Through"
    end

    test "renders secondary power pillar when set", %{conn: conn} do
      module =
        module_fixture(%{power_pillar_1: :power_up, power_pillar_2: :empower})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Power Up"
      assert html =~ "Empower"
    end

    test "omits secondary power pillar separator when not set", %{conn: conn} do
      module = module_fixture(%{power_pillar_1: :power_up, power_pillar_2: nil})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Power Up"
      # The "+" separator between pillars should not appear
      refute html =~ ~r/Power Up.*\+/s
    end

    test "shows success completeness color when 80% or more fields are filled", %{conn: conn} do
      module =
        module_fixture(%{
          overview: "An overview",
          core_concepts: "Core concepts text",
          outcomes: "Outcomes text",
          modifications: "Mod text",
          coach_tip: "Stay focused",
          daily_time: 30,
          weekly_freq: 3
        })

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "text-success"
    end

    test "shows warning completeness color in the 50-79 percent range", %{conn: conn} do
      module = module_fixture()

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "text-warning"
    end

    test "shows error completeness color when below 50 percent", %{conn: conn} do
      module = module_fixture(%{overview: nil, core_concepts: nil})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "text-error"
    end

    test "renders metadata fields when present", %{conn: conn} do
      module =
        module_fixture(%{
          daily_time: 30,
          weekly_freq: 3,
          experience_level: "Intermediate",
          time_to_result: "4 weeks"
        })

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Daily Time"
      assert html =~ "30"
      assert html =~ "Weekly Freq"
      assert html =~ "3x"
      assert html =~ "Experience Level"
      assert html =~ "Intermediate"
      assert html =~ "Time to Result"
      assert html =~ "4 weeks"
    end

    test "renders Yes/No for boolean flags", %{conn: conn} do
      module = module_fixture(%{video_available: true, reward_eligible: false})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Video"
      assert html =~ "Reward Eligible"
      assert html =~ "Yes"
      assert html =~ "No"
    end

    test "renders outcomes section when outcomes are present", %{conn: conn} do
      module = module_fixture(%{outcomes: "Improved focus and energy"})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Outcomes"
      assert html =~ "Improved focus and energy"
    end

    test "renders outcome keywords as tags", %{conn: conn} do
      module =
        module_fixture(%{outcome_keywords: ["energy", "focus", "calm"]})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Outcome Keywords"
      assert html =~ "energy"
      assert html =~ "focus"
      assert html =~ "calm"
    end

    test "renders modifications section", %{conn: conn} do
      module = module_fixture(%{modifications: "Seated alternative available"})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Modifications"
      assert html =~ "Seated alternative available"
    end

    test "renders sources section", %{conn: conn} do
      module = module_fixture(%{sources: "Pubmed reference 12345"})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Sources"
      assert html =~ "Pubmed reference 12345"
    end

    test "renders core concepts section", %{conn: conn} do
      module = module_fixture(%{core_concepts: "Concept A\nConcept B"})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Core Concepts"
      assert html =~ "Concept A"
      assert html =~ "Concept B"
    end

    test "renders protocols sorted by position", %{conn: conn} do
      module = module_fixture()
      protocol_fixture(module, %{position: 2, purpose: "Second purpose"})
      protocol_fixture(module, %{position: 1, purpose: "First purpose"})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")

      first_idx = :binary.match(html, "First purpose") |> elem(0)
      second_idx = :binary.match(html, "Second purpose") |> elem(0)

      assert first_idx < second_idx
      assert html =~ "Protocol 1"
      assert html =~ "Protocol 2"
    end

    test "renders protocol expected outcome when present", %{conn: conn} do
      module = module_fixture()

      protocol_fixture(module, %{
        position: 1,
        expected_outcome: "Higher sustained energy"
      })

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Expected Outcome"
      assert html =~ "Higher sustained energy"
    end

    test "formats missing field names with capitalization", %{conn: conn} do
      module = module_fixture(%{coach_tip: nil, daily_time: nil})

      {:ok, _view, html} = live(conn, ~p"/admin/modules/#{module.id}")
      assert html =~ "Coach Tip"
      assert html =~ "Daily Time"
    end
  end
end
