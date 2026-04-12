defmodule SheCommands.Modules.ProtocolTest do
  use SheCommands.DataCase, async: true

  import SheCommands.ModulesFixtures

  alias SheCommands.Modules.Protocol

  describe "changeset/2" do
    test "valid with required fields" do
      module = module_fixture()

      attrs = %{
        module_id: module.id,
        position: 1,
        purpose: "Build core stability",
        steps: "Step 1: Warm up\nStep 2: Core work",
        prescription: "3 sets of 12 reps"
      }

      changeset = Protocol.changeset(%Protocol{}, attrs)
      assert changeset.valid?
    end

    test "invalid without required fields" do
      changeset = Protocol.changeset(%Protocol{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.module_id
      assert "can't be blank" in errors.position
      assert "can't be blank" in errors.purpose
      assert "can't be blank" in errors.steps
      assert "can't be blank" in errors.prescription
    end

    test "validates position is between 1 and 4" do
      module = module_fixture()

      for invalid_pos <- [0, 5, -1] do
        attrs = %{
          module_id: module.id,
          position: invalid_pos,
          purpose: "Test",
          steps: "Steps",
          prescription: "Prescription"
        }

        changeset = Protocol.changeset(%Protocol{}, attrs)
        assert "is invalid" in errors_on(changeset).position
      end
    end

    test "accepts valid positions 1 through 4" do
      module = module_fixture()

      for pos <- 1..4 do
        attrs = %{
          module_id: module.id,
          position: pos,
          purpose: "Purpose #{pos}",
          steps: "Steps #{pos}",
          prescription: "Prescription #{pos}"
        }

        changeset = Protocol.changeset(%Protocol{}, attrs)
        assert changeset.valid?
      end
    end

    test "accepts expected_outcome as optional" do
      module = module_fixture()

      attrs = %{
        module_id: module.id,
        position: 1,
        purpose: "Purpose",
        steps: "Steps",
        prescription: "Prescription",
        expected_outcome: "Increased flexibility"
      }

      changeset = Protocol.changeset(%Protocol{}, attrs)
      assert changeset.valid?
    end
  end
end
