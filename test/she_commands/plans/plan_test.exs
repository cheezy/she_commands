defmodule SheCommands.Plans.PlanTest do
  use SheCommands.DataCase, async: true

  import SheCommands.AccountsFixtures

  alias SheCommands.Plans.Plan

  describe "changeset/2" do
    test "valid with required fields" do
      user = user_fixture()
      attrs = %{user_id: user.id, plan_type: :weekly}
      changeset = Plan.changeset(%Plan{}, attrs)
      assert changeset.valid?
    end

    test "invalid without required fields" do
      changeset = Plan.changeset(%Plan{}, %{})
      refute changeset.valid?
      errors = errors_on(changeset)
      assert "can't be blank" in errors.user_id
      assert "can't be blank" in errors.plan_type
    end

    test "validates plan_type enum" do
      user = user_fixture()
      changeset = Plan.changeset(%Plan{}, %{user_id: user.id, plan_type: :invalid})
      assert "is invalid" in errors_on(changeset).plan_type
    end

    test "validates status enum" do
      user = user_fixture()

      changeset =
        Plan.changeset(%Plan{}, %{user_id: user.id, plan_type: :weekly, status: :invalid})

      assert "is invalid" in errors_on(changeset).status
    end

    test "defaults status to generating" do
      user = user_fixture()
      changeset = Plan.changeset(%Plan{}, %{user_id: user.id, plan_type: :weekly})
      assert Ecto.Changeset.get_field(changeset, :status) == :generating
    end

    test "accepts all plan types" do
      user = user_fixture()

      for type <- [:weekly, :biweekly, :monthly] do
        changeset = Plan.changeset(%Plan{}, %{user_id: user.id, plan_type: type})
        assert changeset.valid?, "Expected #{type} to be valid"
      end
    end

    test "accepts all statuses" do
      user = user_fixture()

      for status <- [:generating, :active, :completed, :archived] do
        changeset =
          Plan.changeset(%Plan{}, %{user_id: user.id, plan_type: :weekly, status: status})

        assert changeset.valid?, "Expected #{status} to be valid"
      end
    end

    test "accepts optional fields" do
      user = user_fixture()

      attrs = %{
        user_id: user.id,
        plan_type: :monthly,
        goal_statement: "My goal",
        expected_outcomes: "Outcomes",
        schedule: %{"monday" => ["protocol_1"]}
      }

      changeset = Plan.changeset(%Plan{}, attrs)
      assert changeset.valid?
    end
  end

  describe "enum accessors" do
    test "plan_types/0" do
      assert Plan.plan_types() == [:weekly, :biweekly, :monthly]
    end

    test "statuses/0" do
      assert Plan.statuses() == [:generating, :active, :completed, :archived]
    end
  end
end
