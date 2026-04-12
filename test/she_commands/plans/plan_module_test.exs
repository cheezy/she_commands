defmodule SheCommands.Plans.PlanModuleTest do
  use SheCommands.DataCase, async: true

  import SheCommands.ModulesFixtures
  import SheCommands.PlansFixtures

  alias SheCommands.Plans.PlanModule

  describe "changeset/2" do
    test "valid with required fields" do
      plan = plan_fixture()
      module = module_fixture()

      attrs = %{plan_id: plan.id, module_id: module.id, power_pillar: :power_up, position: 1}
      changeset = PlanModule.changeset(%PlanModule{}, attrs)
      assert changeset.valid?
    end

    test "invalid without required fields" do
      changeset = PlanModule.changeset(%PlanModule{}, %{})
      refute changeset.valid?
      errors = errors_on(changeset)
      assert "can't be blank" in errors.plan_id
      assert "can't be blank" in errors.module_id
      assert "can't be blank" in errors.power_pillar
      assert "can't be blank" in errors.position
    end

    test "validates power_pillar enum" do
      plan = plan_fixture()
      module = module_fixture()

      changeset =
        PlanModule.changeset(%PlanModule{}, %{
          plan_id: plan.id,
          module_id: module.id,
          power_pillar: :invalid,
          position: 1
        })

      assert "is invalid" in errors_on(changeset).power_pillar
    end

    test "validates position is positive" do
      plan = plan_fixture()
      module = module_fixture()

      changeset =
        PlanModule.changeset(%PlanModule{}, %{
          plan_id: plan.id,
          module_id: module.id,
          power_pillar: :power_up,
          position: 0
        })

      assert "must be greater than 0" in errors_on(changeset).position
    end

    test "accepts all power pillars" do
      plan = plan_fixture()
      module = module_fixture()

      for pillar <- [:power_up, :power_through, :power_down, :empower] do
        changeset =
          PlanModule.changeset(%PlanModule{}, %{
            plan_id: plan.id,
            module_id: module.id,
            power_pillar: pillar,
            position: 1
          })

        assert changeset.valid?, "Expected #{pillar} to be valid"
      end
    end
  end

  describe "power_pillars/0" do
    test "returns all power pillars" do
      assert PlanModule.power_pillars() == [:power_up, :power_through, :power_down, :empower]
    end
  end
end
