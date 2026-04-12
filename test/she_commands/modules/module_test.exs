defmodule SheCommands.Modules.ModuleTest do
  use SheCommands.DataCase, async: true

  alias SheCommands.Modules.Module

  describe "changeset/2" do
    test "valid with required fields" do
      attrs = %{
        module_id: "MOD-001",
        contributor: "Paula V",
        title: "Mindful Breathing",
        power_pillar_1: :power_down
      }

      changeset = Module.changeset(%Module{}, attrs)
      assert changeset.valid?
    end

    test "invalid without required fields" do
      changeset = Module.changeset(%Module{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.module_id
      assert "can't be blank" in errors.contributor
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.power_pillar_1
    end

    test "validates title length" do
      attrs = %{
        module_id: "MOD-001",
        contributor: "Paula V",
        title: String.duplicate("a", 501),
        power_pillar_1: :power_up
      }

      changeset = Module.changeset(%Module{}, attrs)
      assert "should be at most 500 character(s)" in errors_on(changeset).title
    end

    test "validates power_pillar_1 enum values" do
      attrs = %{
        module_id: "MOD-001",
        contributor: "Paula V",
        title: "Test",
        power_pillar_1: :invalid
      }

      changeset = Module.changeset(%Module{}, attrs)
      assert "is invalid" in errors_on(changeset).power_pillar_1
    end

    test "accepts valid power_pillar_2" do
      attrs = %{
        module_id: "MOD-001",
        contributor: "Paula V",
        title: "Test",
        power_pillar_1: :power_up,
        power_pillar_2: :empower
      }

      changeset = Module.changeset(%Module{}, attrs)
      assert changeset.valid?
    end

    test "validates intensity enum" do
      attrs = %{
        module_id: "MOD-001",
        contributor: "Paula V",
        title: "Test",
        power_pillar_1: :power_up,
        intensity: :extreme
      }

      changeset = Module.changeset(%Module{}, attrs)
      assert "is invalid" in errors_on(changeset).intensity
    end

    test "validates module_type enum" do
      attrs = %{
        module_id: "MOD-001",
        contributor: "Paula V",
        title: "Test",
        power_pillar_1: :power_up,
        module_type: :invalid
      }

      changeset = Module.changeset(%Module{}, attrs)
      assert "is invalid" in errors_on(changeset).module_type
    end

    test "validates lead_time_fit enum" do
      attrs = %{
        module_id: "MOD-001",
        contributor: "Paula V",
        title: "Test",
        power_pillar_1: :power_up,
        lead_time_fit: :invalid
      }

      changeset = Module.changeset(%Module{}, attrs)
      assert "is invalid" in errors_on(changeset).lead_time_fit
    end

    test "accepts all optional fields" do
      attrs = %{
        module_id: "MOD-001",
        contributor: "Paula V",
        title: "Complete Module",
        power_pillar_1: :power_up,
        power_pillar_2: :empower,
        overview: "Overview text",
        core_concepts: "Core concepts",
        module_type: :bespoke,
        outcomes: "Outcomes text",
        protocol_sequencing: "Sequential",
        modifications: "Seated alternatives",
        time_to_result: "2 weeks",
        experience_level: "Beginner",
        intensity: :high,
        daily_time: 30,
        weekly_freq: 3,
        daily_freq: 1,
        coach_tip: "Start slow",
        coach_tip_attribution: "Paula V",
        video_available: true,
        sources: "Research paper 1",
        reward_eligible: true,
        complementary_module_ids: [2, 3],
        outcome_keywords: ["Confidence", "Clarity"],
        lead_time_fit: :long
      }

      changeset = Module.changeset(%Module{}, attrs)
      assert changeset.valid?
    end
  end

  describe "enum accessors" do
    test "power_pillars/0" do
      assert Module.power_pillars() == [:power_up, :power_through, :power_down, :empower]
    end

    test "intensities/0" do
      assert Module.intensities() == [:low, :moderate, :high]
    end

    test "module_types/0" do
      assert Module.module_types() == [:foundational, :secondary, :assisted, :bespoke]
    end

    test "lead_time_fits/0" do
      assert Module.lead_time_fits() == [:short, :medium, :long]
    end
  end
end
