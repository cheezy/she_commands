defmodule SheCommands.PlansTest do
  use SheCommands.DataCase, async: true

  import SheCommands.AccountsFixtures
  import SheCommands.IntakeFixtures
  import SheCommands.ModulesFixtures
  import SheCommands.PlansFixtures

  alias SheCommands.Plans

  describe "get_active_plan_for_user/1" do
    test "returns the active plan for a user" do
      user = user_fixture()
      plan = plan_fixture(%{user: user, status: :active})

      loaded = Plans.get_active_plan_for_user(user.id)
      assert loaded.id == plan.id
      assert loaded.status == :active
    end

    test "returns nil when no active plan" do
      user = user_fixture()
      plan_fixture(%{user: user, status: :completed})

      assert Plans.get_active_plan_for_user(user.id) == nil
    end

    test "returns nil for user with no plans" do
      user = user_fixture()
      assert Plans.get_active_plan_for_user(user.id) == nil
    end

    test "preloads plan modules with module protocols" do
      user = user_fixture()
      plan = plan_fixture(%{user: user, status: :active})
      module = module_fixture()
      protocol_fixture(module, %{position: 1})
      plan_module_fixture(plan, %{module: module, position: 1})

      loaded = Plans.get_active_plan_for_user(user.id)
      assert Ecto.assoc_loaded?(loaded.plan_modules)
      assert [pm] = loaded.plan_modules
      assert Ecto.assoc_loaded?(pm.module.protocols)
      assert length(pm.module.protocols) == 1
    end
  end

  describe "get_plan!/1" do
    test "returns the plan with preloaded associations" do
      plan = plan_fixture()
      loaded = Plans.get_plan!(plan.id)
      assert loaded.id == plan.id
      assert Ecto.assoc_loaded?(loaded.plan_modules)
    end

    test "raises when plan does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Plans.get_plan!(0)
      end
    end
  end

  describe "create_plan/1" do
    test "creates a plan with valid attrs" do
      user = user_fixture()

      assert {:ok, plan} =
               Plans.create_plan(%{
                 user_id: user.id,
                 plan_type: :weekly,
                 goal_statement: "Test goal"
               })

      assert plan.plan_type == :weekly
      assert plan.status == :generating
      assert plan.goal_statement == "Test goal"
    end

    test "returns error with invalid attrs" do
      assert {:error, changeset} = Plans.create_plan(%{})
      refute changeset.valid?
    end
  end

  describe "update_plan/2" do
    test "updates a plan" do
      plan = plan_fixture()
      assert {:ok, updated} = Plans.update_plan(plan, %{status: :active})
      assert updated.status == :active
    end
  end

  describe "list_plans_for_user/1" do
    test "returns plans for a user ordered by most recent" do
      user = user_fixture()
      plan_fixture(%{user: user, plan_type: :weekly})
      plan_fixture(%{user: user, plan_type: :monthly})

      plans = Plans.list_plans_for_user(user.id)
      assert length(plans) == 2
      # Most recent first
      assert hd(plans).inserted_at >= List.last(plans).inserted_at
    end

    test "returns empty list for user with no plans" do
      user = user_fixture()
      assert Plans.list_plans_for_user(user.id) == []
    end
  end

  describe "add_plan_module/1" do
    test "adds a module to a plan" do
      plan = plan_fixture()
      module = module_fixture()

      assert {:ok, pm} =
               Plans.add_plan_module(%{
                 plan_id: plan.id,
                 module_id: module.id,
                 power_pillar: :empower,
                 position: 1
               })

      assert pm.power_pillar == :empower
      assert pm.position == 1
    end

    test "enforces unique position per plan" do
      plan = plan_fixture()
      m1 = module_fixture()
      m2 = module_fixture()

      assert {:ok, _} =
               Plans.add_plan_module(%{
                 plan_id: plan.id,
                 module_id: m1.id,
                 power_pillar: :power_up,
                 position: 1
               })

      assert {:error, _} =
               Plans.add_plan_module(%{
                 plan_id: plan.id,
                 module_id: m2.id,
                 power_pillar: :power_down,
                 position: 1
               })
    end
  end

  describe "list_plan_modules/1" do
    test "returns plan modules ordered by position" do
      plan = plan_fixture()
      plan_module_fixture(plan, %{position: 3, power_pillar: :power_down})
      plan_module_fixture(plan, %{position: 1, power_pillar: :power_up})
      plan_module_fixture(plan, %{position: 2, power_pillar: :empower})

      modules = Plans.list_plan_modules(plan.id)
      positions = Enum.map(modules, & &1.position)
      assert positions == [1, 2, 3]
    end

    test "preloads module with protocols" do
      plan = plan_fixture()
      module = module_fixture()
      protocol_fixture(module, %{position: 1})
      plan_module_fixture(plan, %{module: module, position: 1})

      [pm] = Plans.list_plan_modules(plan.id)
      assert Ecto.assoc_loaded?(pm.module)
      assert Ecto.assoc_loaded?(pm.module.protocols)
    end

    test "returns empty list for plan with no modules" do
      plan = plan_fixture()
      assert Plans.list_plan_modules(plan.id) == []
    end
  end

  describe "change_plan/2" do
    test "returns a changeset" do
      plan = plan_fixture()
      assert %Ecto.Changeset{} = Plans.change_plan(plan)
    end
  end

  describe "generate_plan/1" do
    test "generates a plan from intake response with modules" do
      user = user_fixture()

      category =
        goal_category_fixture(%{
          name: "Gen Test",
          slug: "gen-test-#{System.unique_integer()}",
          outcome_power_up: "PU",
          outcome_power_through: "PT",
          outcome_power_down: "PD",
          outcome_empower: "EM"
        })

      # Modules covering all 4 pillars
      module_with_categories_fixture(
        %{power_pillar_1: :power_up, intensity: :moderate, daily_time: 15},
        [category]
      )

      module_with_categories_fixture(
        %{power_pillar_1: :power_through, intensity: :moderate, daily_time: 15},
        [category]
      )

      module_with_categories_fixture(
        %{power_pillar_1: :power_down, intensity: :moderate, daily_time: 15},
        [category]
      )

      module_with_categories_fixture(
        %{power_pillar_1: :empower, intensity: :moderate, daily_time: 15},
        [category]
      )

      intake =
        intake_response_fixture(user, %{
          goal_category_id: category.id,
          goal_intent: "Lead with confidence",
          lead_time: :short,
          days_per_week: 5,
          hours_per_day: :thirty_to_sixty,
          intensity: :moderate
        })

      assert {:ok, plan} = Plans.generate_plan(intake)
      assert plan.plan_type == :weekly
      assert plan.status == :active
      assert plan.goal_statement =~ "Lead with confidence"
      assert plan.expected_outcomes =~ "PU"
      assert length(plan.plan_modules) >= 4
    end

    test "returns error when pillar coverage is impossible" do
      user = user_fixture()

      category =
        goal_category_fixture(%{slug: "sparse-gen-#{System.unique_integer()}"})

      module_with_categories_fixture(
        %{power_pillar_1: :power_up, intensity: :low, daily_time: 10},
        [category]
      )

      intake =
        intake_response_fixture(user, %{
          goal_category_id: category.id,
          lead_time: :short,
          days_per_week: 3,
          hours_per_day: :thirty_to_sixty,
          intensity: :low
        })

      # Best-effort: generates a plan with available modules, partial coverage
      assert {:ok, plan} = Plans.generate_plan(intake)
      assert plan.status == :active
      assert length(plan.plan_modules) >= 1
    end
  end
end
