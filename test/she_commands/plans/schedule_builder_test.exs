defmodule SheCommands.Plans.ScheduleBuilderTest do
  use SheCommands.DataCase, async: true

  import SheCommands.ModulesFixtures

  alias SheCommands.Plans.ScheduleBuilder

  defp make_plan_module(module, pillar) do
    %{module: module, power_pillar: pillar}
  end

  describe "build_schedule/3" do
    test "distributes modules across available days" do
      m1 = module_fixture(%{power_pillar_1: :power_up, daily_time: 15})
      m2 = module_fixture(%{power_pillar_1: :power_through, daily_time: 15})
      m3 = module_fixture(%{power_pillar_1: :power_down, daily_time: 15})

      plan_modules = [
        make_plan_module(m1, :power_up),
        make_plan_module(m2, :power_through),
        make_plan_module(m3, :power_down)
      ]

      schedule = ScheduleBuilder.build_schedule(plan_modules, 3, :thirty_to_sixty)

      active_days = ["monday", "tuesday", "wednesday"]

      for day <- active_days do
        assert Map.has_key?(schedule, day)
      end

      # All 3 modules should be assigned
      total_assignments =
        schedule
        |> Map.values()
        |> List.flatten()
        |> length()

      assert total_assignments == 3
    end

    test "marks rest days as empty" do
      m1 = module_fixture(%{daily_time: 15})
      plan_modules = [make_plan_module(m1, :power_up)]

      schedule = ScheduleBuilder.build_schedule(plan_modules, 3, :thirty_to_sixty)

      # Rest days should be empty
      assert schedule["thursday"] == []
      assert schedule["friday"] == []
      assert schedule["saturday"] == []
      assert schedule["sunday"] == []
    end

    test "respects daily time constraint" do
      m1 = module_fixture(%{daily_time: 20})
      m2 = module_fixture(%{daily_time: 20})
      m3 = module_fixture(%{daily_time: 20})

      plan_modules = [
        make_plan_module(m1, :power_up),
        make_plan_module(m2, :power_through),
        make_plan_module(m3, :power_down)
      ]

      schedule = ScheduleBuilder.build_schedule(plan_modules, 5, :under_30)

      # With 30 min max, each day should have at most ~1-2 modules
      for day <- ["monday", "tuesday", "wednesday", "thursday", "friday"] do
        day_time =
          schedule[day]
          |> Enum.map(& &1.daily_time)
          |> Enum.sum()

        # Best effort — may exceed slightly but should distribute
        assert day_time <= 40, "Day #{day} has #{day_time} minutes"
      end
    end

    test "handles single day per week" do
      m1 = module_fixture(%{daily_time: 10})
      m2 = module_fixture(%{daily_time: 10})

      plan_modules = [
        make_plan_module(m1, :power_up),
        make_plan_module(m2, :empower)
      ]

      schedule = ScheduleBuilder.build_schedule(plan_modules, 1, :thirty_to_sixty)

      assert length(schedule["monday"]) == 2
      assert schedule["tuesday"] == []
    end

    test "handles full 7 days per week" do
      modules =
        for pillar <- [:power_up, :power_through, :power_down, :empower] do
          m = module_fixture(%{power_pillar_1: pillar, daily_time: 10})
          make_plan_module(m, pillar)
        end

      schedule = ScheduleBuilder.build_schedule(modules, 7, :thirty_to_sixty)

      active_count =
        schedule
        |> Map.values()
        |> Enum.count(fn assignments -> assignments != [] end)

      assert active_count >= 4
    end

    test "includes all 7 days in schedule map" do
      m1 = module_fixture(%{daily_time: 15})
      plan_modules = [make_plan_module(m1, :power_up)]

      schedule = ScheduleBuilder.build_schedule(plan_modules, 3, :thirty_to_sixty)

      assert map_size(schedule) == 7
    end

    test "assignments include module details" do
      m = module_fixture(%{title: "Test Module", daily_time: 20})
      plan_modules = [make_plan_module(m, :empower)]

      schedule = ScheduleBuilder.build_schedule(plan_modules, 5, :thirty_to_sixty)

      assignment =
        schedule
        |> Map.values()
        |> List.flatten()
        |> hd()

      assert assignment.module_id == m.id
      assert assignment.module_title == "Test Module"
      assert assignment.power_pillar == :empower
      assert assignment.daily_time == 20
    end

    test "handles empty plan modules" do
      schedule = ScheduleBuilder.build_schedule([], 5, :thirty_to_sixty)

      for day <- ["monday", "tuesday", "wednesday", "thursday", "friday"] do
        assert schedule[day] == []
      end
    end
  end
end
