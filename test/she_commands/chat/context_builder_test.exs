defmodule SheCommands.Chat.ContextBuilderTest do
  use SheCommands.DataCase, async: true

  import SheCommands.AccountsFixtures
  import SheCommands.IntakeFixtures
  import SheCommands.ModulesFixtures
  import SheCommands.PlansFixtures

  alias SheCommands.Chat.ContextBuilder
  alias SheCommands.Plans

  defp build_plan_with_modules(opts \\ []) do
    user = opts[:user] || user_fixture()
    goal_category = opts[:goal_category] || goal_category_fixture()
    plan = create_plan_from_opts(opts, user)
    modules = opts[:modules] || [build_default_module(goal_category)]
    attach_modules_to_plan(plan, modules)
    Plans.get_plan!(plan.id)
  end

  defp create_plan_from_opts(opts, user) do
    plan_fixture(%{
      user: user,
      goal_statement: opts[:goal_statement] || "Become a confident leader",
      expected_outcomes: opts[:expected_outcomes] || "Improved presence and clarity",
      schedule: opts[:schedule] || %{"monday" => [%{module_title: "Power Module"}]}
    })
  end

  defp attach_modules_to_plan(plan, modules) do
    Enum.each(modules, fn {mod, pillar, position} ->
      plan_module_fixture(plan, %{module: mod, power_pillar: pillar, position: position})
    end)
  end

  defp build_default_module(goal_category) do
    mod =
      module_with_categories_fixture(
        %{
          title: "Power Foundations",
          overview: "Build your inner strength",
          core_concepts: "Mindset and resilience",
          outcomes: "Greater confidence"
        },
        [goal_category]
      )

    protocol_fixture(mod, %{
      position: 1,
      purpose: "Morning Ritual",
      steps: "Wake and breathe",
      prescription: "Daily for 10 min",
      expected_outcome: "Calm start"
    })

    {mod, :power_up, 1}
  end

  describe "build_context/1" do
    test "includes plan goal statement and expected outcomes" do
      plan = build_plan_with_modules()
      context = ContextBuilder.build_context(plan)

      assert context =~ "Become a confident leader"
      assert context =~ "Improved presence and clarity"
    end

    test "includes all module titles and overviews" do
      goal_category = goal_category_fixture()

      mod1 =
        module_with_categories_fixture(
          %{title: "Module Alpha", overview: "Alpha overview"},
          [goal_category]
        )

      protocol_fixture(mod1, %{position: 1, purpose: "P1", steps: "S1", prescription: "Rx1"})

      mod2 =
        module_with_categories_fixture(
          %{title: "Module Beta", overview: "Beta overview"},
          [goal_category]
        )

      protocol_fixture(mod2, %{position: 1, purpose: "P2", steps: "S2", prescription: "Rx2"})

      plan =
        build_plan_with_modules(
          goal_category: goal_category,
          modules: [{mod1, :power_up, 1}, {mod2, :power_through, 2}]
        )

      context = ContextBuilder.build_context(plan)

      assert context =~ "Module Alpha"
      assert context =~ "Alpha overview"
      assert context =~ "Module Beta"
      assert context =~ "Beta overview"
    end

    test "includes protocol details" do
      plan = build_plan_with_modules()
      context = ContextBuilder.build_context(plan)

      assert context =~ "Morning Ritual"
      assert context =~ "Wake and breathe"
      assert context =~ "Daily for 10 min"
      assert context =~ "Calm start"
    end

    test "includes goal category description" do
      category =
        goal_category_fixture(%{
          name: "Commanding Presence",
          description: "Build executive presence"
        })

      plan = build_plan_with_modules(goal_category: category)
      context = ContextBuilder.build_context(plan)

      assert context =~ "Commanding Presence"
      assert context =~ "Build executive presence"
    end

    test "handles plan with no schedule gracefully" do
      plan = build_plan_with_modules(schedule: %{})
      context = ContextBuilder.build_context(plan)

      refute context =~ "Weekly Schedule"
      assert context =~ "Become a confident leader"
    end

    test "handles plan with no modules" do
      user = user_fixture()

      plan =
        plan_fixture(%{
          user: user,
          goal_statement: "A goal",
          expected_outcomes: "Some outcomes"
        })

      loaded_plan = Plans.get_plan!(plan.id)
      context = ContextBuilder.build_context(loaded_plan)

      assert is_binary(context)
      assert context =~ "A goal"
      refute context =~ "Modules"
    end

    test "handles module with nil overview and core_concepts" do
      goal_category = goal_category_fixture()

      mod =
        module_with_categories_fixture(
          %{title: "Bare Module", overview: nil, core_concepts: nil},
          [goal_category]
        )

      protocol_fixture(mod, %{position: 1, purpose: "P1", steps: "S1", prescription: "Rx1"})

      plan =
        build_plan_with_modules(
          goal_category: goal_category,
          modules: [{mod, :power_up, 1}]
        )

      context = ContextBuilder.build_context(plan)

      assert context =~ "Bare Module"
      refute context =~ "Overview:"
      refute context =~ "Core Concepts:"
    end

    test "handles protocol with nil expected_outcome" do
      goal_category = goal_category_fixture()
      mod = module_with_categories_fixture(%{title: "Test Mod"}, [goal_category])

      protocol_fixture(mod, %{
        position: 1,
        purpose: "No Outcome Protocol",
        steps: "Do things",
        prescription: "Often",
        expected_outcome: nil
      })

      plan =
        build_plan_with_modules(
          goal_category: goal_category,
          modules: [{mod, :power_up, 1}]
        )

      context = ContextBuilder.build_context(plan)

      assert context =~ "No Outcome Protocol"
      refute context =~ "Expected Outcome:"
    end

    test "orders modules by position" do
      goal_category = goal_category_fixture()

      mod_second =
        module_with_categories_fixture(%{title: "Second Module"}, [goal_category])

      protocol_fixture(mod_second, %{position: 1, purpose: "P", steps: "S", prescription: "R"})

      mod_first =
        module_with_categories_fixture(%{title: "First Module"}, [goal_category])

      protocol_fixture(mod_first, %{position: 1, purpose: "P", steps: "S", prescription: "R"})

      plan =
        build_plan_with_modules(
          goal_category: goal_category,
          modules: [{mod_first, :power_up, 1}, {mod_second, :power_through, 2}]
        )

      context = ContextBuilder.build_context(plan)

      first_pos = :binary.match(context, "First Module") |> elem(0)
      second_pos = :binary.match(context, "Second Module") |> elem(0)
      assert first_pos < second_pos
    end

    test "deduplicates goal categories" do
      category = goal_category_fixture(%{name: "Shared Category", description: "Shared desc"})

      mod1 = module_with_categories_fixture(%{title: "Mod A"}, [category])
      protocol_fixture(mod1, %{position: 1, purpose: "P", steps: "S", prescription: "R"})

      mod2 = module_with_categories_fixture(%{title: "Mod B"}, [category])
      protocol_fixture(mod2, %{position: 1, purpose: "P", steps: "S", prescription: "R"})

      plan =
        build_plan_with_modules(
          goal_category: category,
          modules: [{mod1, :power_up, 1}, {mod2, :power_through, 2}]
        )

      context = ContextBuilder.build_context(plan)

      matches =
        context
        |> String.split("Shared Category")
        |> length()

      # String split produces N+1 parts for N occurrences — expect exactly 2 (one occurrence)
      assert matches == 2
    end
  end

  describe "build_system_prompt/1" do
    test "includes brand voice instructions" do
      plan = build_plan_with_modules()
      prompt = ContextBuilder.build_system_prompt(plan)

      assert prompt =~ "direct, warm"
      assert prompt =~ "trusted coach"
    end

    test "includes safety guardrails" do
      plan = build_plan_with_modules()
      prompt = ContextBuilder.build_system_prompt(plan)

      assert prompt =~ "medical advice"
      assert prompt =~ "nutritional advice"
      assert prompt =~ "fitness programming"
      assert prompt =~ "qualified professional"
    end

    test "includes plan context" do
      plan = build_plan_with_modules()
      prompt = ContextBuilder.build_system_prompt(plan)

      assert prompt =~ "Become a confident leader"
      assert prompt =~ "Power Foundations"
    end
  end

  describe "integration" do
    test "full context build with realistic plan fixture" do
      goal_category =
        goal_category_fixture(%{
          name: "Executive Presence",
          description: "Command attention and inspire confidence"
        })

      mod1 =
        module_with_categories_fixture(
          %{
            title: "Vocal Authority",
            overview: "Master your speaking voice",
            core_concepts: "Resonance and projection",
            outcomes: "Confident vocal delivery",
            coach_tip: "Practice with a wall 2 feet away"
          },
          [goal_category]
        )

      protocol_fixture(mod1, %{
        position: 1,
        purpose: "Voice Warm-Up",
        steps: "Hum for 2 minutes, then speak a phrase",
        prescription: "Before every meeting",
        expected_outcome: "Relaxed vocal cords"
      })

      protocol_fixture(mod1, %{
        position: 2,
        purpose: "Power Pause",
        steps: "Pause 3 seconds before key points",
        prescription: "During presentations",
        expected_outcome: "Audience attention"
      })

      mod2 =
        module_with_categories_fixture(
          %{
            title: "Body Language Mastery",
            overview: "Use physicality to project confidence",
            core_concepts: "Posture, gestures, eye contact",
            outcomes: "Non-verbal impact"
          },
          [goal_category]
        )

      protocol_fixture(mod2, %{
        position: 1,
        purpose: "Power Posture",
        steps: "Stand tall, shoulders back, chin level",
        prescription: "2 minutes before high-stakes moments"
      })

      plan =
        build_plan_with_modules(
          goal_category: goal_category,
          goal_statement: "Lead with commanding presence in every room",
          expected_outcomes: "Others notice my confidence and authority",
          schedule: %{
            "monday" => [%{module_title: "Vocal Authority"}],
            "wednesday" => [%{module_title: "Body Language Mastery"}],
            "friday" => [%{module_title: "Vocal Authority"}]
          },
          modules: [{mod1, :power_up, 1}, {mod2, :power_through, 2}]
        )

      prompt = ContextBuilder.build_system_prompt(plan)

      # System prompt structure
      assert prompt =~ "## Role"
      assert prompt =~ "## Voice"
      assert prompt =~ "## Plan Context"
      assert prompt =~ "## Boundaries"

      # Plan content
      assert prompt =~ "Lead with commanding presence"
      assert prompt =~ "Others notice my confidence"
      assert prompt =~ "Executive Presence"
      assert prompt =~ "Vocal Authority"
      assert prompt =~ "Body Language Mastery"
      assert prompt =~ "Voice Warm-Up"
      assert prompt =~ "Power Pause"
      assert prompt =~ "Power Posture"

      # Safety
      assert prompt =~ "medical advice"
    end
  end
end
