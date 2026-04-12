defmodule SheCommands.Plans.EngineTest do
  use SheCommands.DataCase, async: true

  import SheCommands.AccountsFixtures
  import SheCommands.IntakeFixtures
  import SheCommands.ModulesFixtures

  alias SheCommands.Plans.Engine

  describe "determine_plan_type/1" do
    test "short lead time maps to weekly" do
      assert Engine.determine_plan_type(:short) == :weekly
    end

    test "medium lead time maps to biweekly" do
      assert Engine.determine_plan_type(:medium) == :biweekly
    end

    test "long lead time maps to monthly" do
      assert Engine.determine_plan_type(:long) == :monthly
    end
  end

  describe "map_hours_per_day/1" do
    test "under_30 maps to 30 minutes" do
      assert Engine.map_hours_per_day(:under_30) == 30
    end

    test "thirty_to_sixty maps to 60 minutes" do
      assert Engine.map_hours_per_day(:thirty_to_sixty) == 60
    end

    test "over_sixty maps to 90 minutes" do
      assert Engine.map_hours_per_day(:over_sixty) == 90
    end
  end

  describe "max_modules_for_plan/2" do
    test "weekly always returns 4" do
      assert Engine.max_modules_for_plan(:weekly, 1) == 4
      assert Engine.max_modules_for_plan(:weekly, 7) == 4
    end

    test "biweekly with 3 or fewer days returns 4" do
      assert Engine.max_modules_for_plan(:biweekly, 3) == 4
    end

    test "biweekly with more than 3 days returns 8" do
      assert Engine.max_modules_for_plan(:biweekly, 4) == 8
    end

    test "monthly with 3 or fewer days returns 4" do
      assert Engine.max_modules_for_plan(:monthly, 3) == 4
    end

    test "monthly with more than 3 days returns 8" do
      assert Engine.max_modules_for_plan(:monthly, 5) == 8
    end
  end

  describe "select_modules_with_pillar_coverage/2" do
    test "selects one module per pillar when all covered" do
      m1 = module_fixture(%{power_pillar_1: :power_up})
      m2 = module_fixture(%{power_pillar_1: :power_through})
      m3 = module_fixture(%{power_pillar_1: :power_down})
      m4 = module_fixture(%{power_pillar_1: :empower})

      {:ok, selected} =
        Engine.select_modules_with_pillar_coverage([m1, m2, m3, m4], 4)

      pillars = Enum.map(selected, & &1.power_pillar)
      assert :power_up in pillars
      assert :power_through in pillars
      assert :power_down in pillars
      assert :empower in pillars
    end

    test "returns error when pillar cannot be covered" do
      m1 = module_fixture(%{power_pillar_1: :power_up})
      m2 = module_fixture(%{power_pillar_1: :power_up})

      assert {:error, {:insufficient_coverage, uncovered}} =
               Engine.select_modules_with_pillar_coverage([m1, m2], 4)

      assert :power_through in uncovered
      assert :power_down in uncovered
      assert :empower in uncovered
    end

    test "module with power_pillar_2 can cover either pillar" do
      m1 = module_fixture(%{power_pillar_1: :power_up, power_pillar_2: :power_through})
      m2 = module_fixture(%{power_pillar_1: :power_down})
      m3 = module_fixture(%{power_pillar_1: :empower})
      m4 = module_fixture(%{power_pillar_1: :power_through})

      {:ok, selected} =
        Engine.select_modules_with_pillar_coverage([m1, m2, m3, m4], 4)

      pillars = Enum.map(selected, & &1.power_pillar)
      assert :power_up in pillars
      assert :power_through in pillars
      assert :power_down in pillars
      assert :empower in pillars
    end

    test "fills remaining capacity with extra modules" do
      m1 = module_fixture(%{power_pillar_1: :power_up})
      m2 = module_fixture(%{power_pillar_1: :power_through})
      m3 = module_fixture(%{power_pillar_1: :power_down})
      m4 = module_fixture(%{power_pillar_1: :empower})
      m5 = module_fixture(%{power_pillar_1: :power_up})

      {:ok, selected} =
        Engine.select_modules_with_pillar_coverage([m1, m2, m3, m4, m5], 8)

      assert length(selected) == 5
    end

    test "returns empty list when no candidates" do
      assert {:error, {:insufficient_coverage, _}} =
               Engine.select_modules_with_pillar_coverage([], 4)
    end
  end

  describe "build_goal_statement/2" do
    test "combines goal intent with category name" do
      response = %{goal_intent: "Lead with confidence in board meetings"}
      category = goal_category_fixture(%{name: "Commanding Presence"})

      result = Engine.build_goal_statement(response, category)
      assert result =~ "Lead with confidence in board meetings"
      assert result =~ "Commanding Presence"
    end

    test "handles nil goal intent" do
      response = %{goal_intent: nil}
      category = goal_category_fixture(%{name: "Decision Making"})

      result = Engine.build_goal_statement(response, category)
      assert result =~ "Decision Making"
    end

    test "handles empty goal intent" do
      response = %{goal_intent: "  "}
      category = goal_category_fixture(%{name: "Stress & Anxiety"})

      result = Engine.build_goal_statement(response, category)
      assert result =~ "plan is ready"
    end
  end

  describe "build_expected_outcomes/1" do
    test "builds outcomes from per-pillar descriptions" do
      category =
        goal_category_fixture(%{
          outcome_power_up: "Fuel energy",
          outcome_power_through: "Build stamina",
          outcome_power_down: "Manage stress",
          outcome_empower: "Lead with clarity"
        })

      result = Engine.build_expected_outcomes(category)
      assert result =~ "Power Up: Fuel energy"
      assert result =~ "Power Through: Build stamina"
      assert result =~ "Power Down: Manage stress"
      assert result =~ "Empower: Lead with clarity"
    end

    test "skips empty outcomes" do
      category =
        goal_category_fixture(%{
          outcome_power_up: "Fuel energy",
          outcome_power_through: "",
          outcome_power_down: nil,
          outcome_empower: "Lead"
        })

      result = Engine.build_expected_outcomes(category)
      assert result =~ "Power Up: Fuel energy"
      assert result =~ "Empower: Lead"
      refute result =~ "Power Through"
      refute result =~ "Power Down"
    end
  end

  describe "generate/2" do
    setup do
      user = user_fixture()

      category =
        goal_category_fixture(%{
          name: "Test Cat",
          slug: "test-gen-#{System.unique_integer()}",
          outcome_power_up: "PU outcome",
          outcome_power_through: "PT outcome",
          outcome_power_down: "PD outcome",
          outcome_empower: "EM outcome"
        })

      # Create modules covering all 4 pillars for this category
      mod_attrs = %{intensity: :moderate, daily_time: 15}

      m1 =
        module_with_categories_fixture(
          Map.put(mod_attrs, :power_pillar_1, :power_up),
          [category]
        )

      m2 =
        module_with_categories_fixture(
          Map.put(mod_attrs, :power_pillar_1, :power_through),
          [category]
        )

      m3 =
        module_with_categories_fixture(
          Map.put(mod_attrs, :power_pillar_1, :power_down),
          [category]
        )

      m4 =
        module_with_categories_fixture(
          Map.put(mod_attrs, :power_pillar_1, :empower),
          [category]
        )

      intake =
        intake_response_fixture(user, %{
          goal_category_id: category.id,
          goal_intent: "Be more confident",
          lead_time: :short,
          days_per_week: 5,
          hours_per_day: :thirty_to_sixty,
          intensity: :moderate
        })

      %{user: user, category: category, intake: intake, modules: [m1, m2, m3, m4]}
    end

    test "generates plan with correct plan type", %{intake: intake, category: category} do
      {:ok, plan_attrs} = Engine.generate(intake, category)
      assert plan_attrs.plan_type == :weekly
    end

    test "generates goal statement", %{intake: intake, category: category} do
      {:ok, plan_attrs} = Engine.generate(intake, category)
      assert plan_attrs.goal_statement =~ "Be more confident"
    end

    test "generates expected outcomes", %{intake: intake, category: category} do
      {:ok, plan_attrs} = Engine.generate(intake, category)
      assert plan_attrs.expected_outcomes =~ "PU outcome"
    end

    test "selects modules covering all 4 pillars", %{intake: intake, category: category} do
      {:ok, plan_attrs} = Engine.generate(intake, category)
      pillars = Enum.map(plan_attrs.selected_modules, & &1.power_pillar)
      assert :power_up in pillars
      assert :power_through in pillars
      assert :power_down in pillars
      assert :empower in pillars
    end

    test "returns error when not enough modules for coverage" do
      user = user_fixture()
      category = goal_category_fixture(%{slug: "sparse-#{System.unique_integer()}"})
      # Only create 1 module — can't cover 4 pillars
      module_with_categories_fixture(%{power_pillar_1: :power_up, intensity: :low}, [category])

      intake =
        intake_response_fixture(user, %{
          goal_category_id: category.id,
          lead_time: :short,
          days_per_week: 3,
          hours_per_day: :thirty_to_sixty,
          intensity: :low
        })

      assert {:error, {:insufficient_coverage, _}} = Engine.generate(intake, category)
    end
  end

  describe "maybe_add_complementary/3" do
    test "adds complementary when capacity allows" do
      m1 = module_fixture(%{power_pillar_1: :power_up})
      m2 = module_fixture(%{power_pillar_1: :power_through, complementary_module_ids: [m1.id]})

      selected = [%{module: m2, power_pillar: :power_through}]
      result = Engine.maybe_add_complementary(selected, 8, 5)

      assert length(result) == 2
    end

    test "skips when days_per_week <= 3" do
      m1 = module_fixture(%{power_pillar_1: :power_up})
      m2 = module_fixture(%{complementary_module_ids: [m1.id]})

      selected = [%{module: m2, power_pillar: :power_up}]
      result = Engine.maybe_add_complementary(selected, 8, 3)

      assert length(result) == 1
    end

    test "skips when already at 5 or more modules" do
      modules =
        for _ <- 1..5 do
          m = module_fixture()
          %{module: m, power_pillar: :power_up}
        end

      result = Engine.maybe_add_complementary(modules, 8, 5)
      assert length(result) == 5
    end

    test "skips when no complementary module ids" do
      m1 = module_fixture(%{complementary_module_ids: []})
      selected = [%{module: m1, power_pillar: :power_up}]
      result = Engine.maybe_add_complementary(selected, 8, 5)
      assert length(result) == 1
    end
  end

  describe "generate/2 edge cases" do
    test "medium lead time generates biweekly plan" do
      user = user_fixture()

      category =
        goal_category_fixture(%{slug: "biweekly-#{System.unique_integer()}"})

      mod_attrs = %{intensity: :low, daily_time: 10}

      for pillar <- [:power_up, :power_through, :power_down, :empower] do
        module_with_categories_fixture(
          Map.put(mod_attrs, :power_pillar_1, pillar),
          [category]
        )
      end

      intake =
        intake_response_fixture(user, %{
          goal_category_id: category.id,
          lead_time: :medium,
          days_per_week: 5,
          hours_per_day: :thirty_to_sixty,
          intensity: :low
        })

      {:ok, plan_attrs} = Engine.generate(intake, category)
      assert plan_attrs.plan_type == :biweekly
    end

    test "long lead time generates monthly plan" do
      user = user_fixture()

      category =
        goal_category_fixture(%{slug: "monthly-#{System.unique_integer()}"})

      mod_attrs = %{intensity: :high, daily_time: 20}

      for pillar <- [:power_up, :power_through, :power_down, :empower] do
        module_with_categories_fixture(
          Map.put(mod_attrs, :power_pillar_1, pillar),
          [category]
        )
      end

      intake =
        intake_response_fixture(user, %{
          goal_category_id: category.id,
          lead_time: :long,
          days_per_week: 5,
          hours_per_day: :over_sixty,
          intensity: :high
        })

      {:ok, plan_attrs} = Engine.generate(intake, category)
      assert plan_attrs.plan_type == :monthly
    end

    test "user with very limited time still gets 4 pillars covered" do
      user = user_fixture()

      category =
        goal_category_fixture(%{slug: "limited-#{System.unique_integer()}"})

      mod_attrs = %{intensity: :low, daily_time: 5}

      for pillar <- [:power_up, :power_through, :power_down, :empower] do
        module_with_categories_fixture(
          Map.put(mod_attrs, :power_pillar_1, pillar),
          [category]
        )
      end

      intake =
        intake_response_fixture(user, %{
          goal_category_id: category.id,
          lead_time: :short,
          days_per_week: 1,
          hours_per_day: :under_30,
          intensity: :low
        })

      {:ok, plan_attrs} = Engine.generate(intake, category)
      pillars = Enum.map(plan_attrs.selected_modules, & &1.power_pillar)
      assert length(Enum.uniq(pillars)) == 4
    end
  end
end
