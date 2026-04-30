defmodule SheCommands.IntakeTest do
  use SheCommands.DataCase

  import SheCommands.AccountsFixtures
  import SheCommands.IntakeFixtures

  alias SheCommands.Intake

  describe "goal categories" do
    test "list_goal_categories/0 returns all categories ordered by position" do
      cat1 = goal_category_fixture(%{position: 2})
      cat2 = goal_category_fixture(%{position: 1})

      result = Intake.list_goal_categories()
      assert [first, second] = result
      assert first.id == cat2.id
      assert second.id == cat1.id
    end

    test "list_visible_goal_categories/0 excludes hidden categories" do
      visible = goal_category_fixture(%{position: 1, visible_on_intake: true})
      _hidden = goal_category_fixture(%{position: 2, visible_on_intake: false})

      ids = Intake.list_visible_goal_categories() |> Enum.map(& &1.id)
      assert ids == [visible.id]
    end

    test "list_visible_goal_categories/0 preserves position ordering" do
      late = goal_category_fixture(%{position: 5, visible_on_intake: true})
      early = goal_category_fixture(%{position: 1, visible_on_intake: true})

      result = Intake.list_visible_goal_categories()
      assert Enum.map(result, & &1.id) == [early.id, late.id]
    end

    test "list_goal_categories/0 still returns hidden categories (admin contract)" do
      visible = goal_category_fixture(%{position: 1, visible_on_intake: true})
      hidden = goal_category_fixture(%{position: 2, visible_on_intake: false})

      ids = Intake.list_goal_categories() |> Enum.map(& &1.id) |> Enum.sort()
      assert Enum.sort([visible.id, hidden.id]) == ids
    end

    test "get_goal_category/1 returns the category" do
      category = goal_category_fixture()
      assert Intake.get_goal_category(category.id).id == category.id
    end

    test "get_goal_category_by_slug/1 returns the category" do
      category = goal_category_fixture()
      assert Intake.get_goal_category_by_slug(category.slug).id == category.id
    end

    test "create_goal_category/1 with valid data creates a category" do
      attrs = %{name: "Test Category", slug: "test-category"}
      assert {:ok, category} = Intake.create_goal_category(attrs)
      assert category.name == "Test Category"
      assert category.slug == "test-category"
    end

    test "create_goal_category/1 enforces unique slug" do
      goal_category_fixture(%{slug: "unique-slug"})

      assert {:error, changeset} =
               Intake.create_goal_category(%{name: "Dup", slug: "unique-slug"})

      assert errors_on(changeset).slug != []
    end

    test "create_goal_category/1 defaults visible_on_intake to true when omitted" do
      attrs = %{name: "Default Visibility", slug: "default-visibility-#{System.unique_integer()}"}
      assert {:ok, category} = Intake.create_goal_category(attrs)
      assert category.visible_on_intake == true
    end

    test "create_goal_category/1 honors visible_on_intake when supplied" do
      attrs = %{
        name: "Hidden Category",
        slug: "hidden-#{System.unique_integer()}",
        visible_on_intake: false
      }

      assert {:ok, category} = Intake.create_goal_category(attrs)
      assert category.visible_on_intake == false
    end

    test "update_goal_category/2 updates name and visibility" do
      category = goal_category_fixture(%{visible_on_intake: true})

      assert {:ok, updated} =
               Intake.update_goal_category(category, %{
                 name: "Renamed",
                 visible_on_intake: false
               })

      assert updated.name == "Renamed"
      assert updated.visible_on_intake == false
    end

    test "update_goal_category/2 returns error changeset on slug collision" do
      goal_category_fixture(%{slug: "collide-slug"})
      target = goal_category_fixture(%{slug: "target-slug"})

      assert {:error, changeset} = Intake.update_goal_category(target, %{slug: "collide-slug"})
      assert errors_on(changeset).slug != []
    end

    test "toggle_goal_category_visibility/1 flips visible to hidden" do
      category = goal_category_fixture(%{visible_on_intake: true})

      assert {:ok, updated} = Intake.toggle_goal_category_visibility(category)
      assert updated.visible_on_intake == false
    end

    test "toggle_goal_category_visibility/1 flips hidden to visible" do
      category = goal_category_fixture(%{visible_on_intake: false})

      assert {:ok, updated} = Intake.toggle_goal_category_visibility(category)
      assert updated.visible_on_intake == true
    end
  end

  describe "create_intake_response/1" do
    test "creates an in_progress response for the user" do
      user = user_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      assert response.user_id == user.id
      assert response.status == :in_progress
      assert response.current_step == 1
    end
  end

  describe "get_active_intake_response/1" do
    test "returns the active in_progress response" do
      user = user_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      active = Intake.get_active_intake_response(user)
      assert active.id == response.id
    end

    test "returns nil when no active response exists" do
      user = user_fixture()
      assert Intake.get_active_intake_response(user) == nil
    end

    test "returns the latest in_progress response" do
      user = user_fixture()
      {:ok, _old} = Intake.create_intake_response(user)
      {:ok, new} = Intake.create_intake_response(user)

      active = Intake.get_active_intake_response(user)
      assert active.id == new.id
    end
  end

  describe "get_or_create_active_intake_response/1" do
    test "creates a new response when none exists" do
      user = user_fixture()
      {:ok, response} = Intake.get_or_create_active_intake_response(user)
      assert response.user_id == user.id
      assert response.status == :in_progress
    end

    test "returns existing response when one exists" do
      user = user_fixture()
      {:ok, existing} = Intake.create_intake_response(user)
      {:ok, found} = Intake.get_or_create_active_intake_response(user)
      assert found.id == existing.id
    end
  end

  describe "get_intake_response/2" do
    test "returns the response scoped to user" do
      user = user_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      assert Intake.get_intake_response(user, response.id).id == response.id
    end

    test "returns nil for another user's response" do
      user1 = user_fixture()
      user2 = user_fixture()
      {:ok, response} = Intake.create_intake_response(user1)

      assert Intake.get_intake_response(user2, response.id) == nil
    end
  end

  describe "list_intake_responses/1" do
    test "returns all responses for a user, newest first" do
      user = user_fixture()
      {:ok, first} = Intake.create_intake_response(user)
      {:ok, second} = Intake.create_intake_response(user)

      responses = Intake.list_intake_responses(user)
      assert length(responses) == 2
      assert hd(responses).id == second.id
      assert List.last(responses).id == first.id
    end

    test "does not return other users' responses" do
      user1 = user_fixture()
      user2 = user_fixture()
      {:ok, _} = Intake.create_intake_response(user1)

      assert Intake.list_intake_responses(user2) == []
    end
  end

  describe "update_intake_goal/2" do
    test "updates goal intent and category" do
      user = user_fixture()
      category = goal_category_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      {:ok, updated} =
        Intake.update_intake_goal(response, %{
          goal_intent: "I want to command any room I walk into",
          goal_category_id: category.id
        })

      assert updated.goal_intent == "I want to command any room I walk into"
      assert updated.goal_category_id == category.id
    end
  end

  describe "update_intake_availability/2" do
    test "updates lead_time, days_per_week, hours_per_day, intensity" do
      user = user_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      {:ok, updated} =
        Intake.update_intake_availability(response, %{
          lead_time: :medium,
          days_per_week: 4,
          hours_per_day: :ten_to_thirty,
          intensity: :moderate
        })

      assert updated.lead_time == :medium
      assert updated.days_per_week == 4
      assert updated.hours_per_day == :ten_to_thirty
      assert updated.intensity == :moderate
    end

    test "validates days_per_week range" do
      user = user_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      {:error, changeset} =
        Intake.update_intake_availability(response, %{days_per_week: 8})

      assert errors_on(changeset).days_per_week != []
    end

    test "rejects days_per_week above 5" do
      user = user_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      {:error, changeset} =
        Intake.update_intake_availability(response, %{days_per_week: 6})

      assert errors_on(changeset).days_per_week != []
    end

    test "accepts days_per_week at boundary values 1 and 5" do
      user = user_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      assert {:ok, updated} =
               Intake.update_intake_availability(response, %{days_per_week: 1})

      assert updated.days_per_week == 1

      assert {:ok, updated} =
               Intake.update_intake_availability(updated, %{days_per_week: 5})

      assert updated.days_per_week == 5
    end
  end

  describe "update_intake_preferences/2" do
    test "updates limitations and coaching preference" do
      user = user_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      {:ok, updated} =
        Intake.update_intake_preferences(response, %{
          limitations: ["menopause", "knee_injury"],
          limitations_notes: "Avoiding high impact",
          coaching_preference: :coach_guided
        })

      assert updated.limitations == ["menopause", "knee_injury"]
      assert updated.limitations_notes == "Avoiding high impact"
      assert updated.coaching_preference == :coach_guided
    end
  end

  describe "update_intake_regimen/2" do
    test "updates fitness and personal dev regimen" do
      user = user_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      {:ok, updated} =
        Intake.update_intake_regimen(response, %{
          fitness_regimen: :moderate,
          fitness_regimen_notes: "Yoga 3x/week",
          personal_dev_regimen: :some,
          personal_dev_regimen_notes: "Reading leadership books"
        })

      assert updated.fitness_regimen == :moderate
      assert updated.fitness_regimen_notes == "Yoga 3x/week"
      assert updated.personal_dev_regimen == :some
    end
  end

  describe "update_intake_location/2" do
    test "updates city, province, country, feedback_interest" do
      user = user_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      {:ok, updated} =
        Intake.update_intake_location(response, %{
          city: "Toronto",
          province: "Ontario",
          country: "Canada",
          feedback_interest: true
        })

      assert updated.city == "Toronto"
      assert updated.province == "Ontario"
      assert updated.country == "Canada"
      assert updated.feedback_interest == true
    end
  end

  describe "update_intake_step/2" do
    test "updates the current step" do
      user = user_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      {:ok, updated} = Intake.update_intake_step(response, 5)
      assert updated.current_step == 5
    end

    test "rejects step less than 1" do
      user = user_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      {:error, changeset} = Intake.update_intake_step(response, 0)
      assert errors_on(changeset).current_step != []
    end
  end

  describe "IntakeResponse schema accessors" do
    test "statuses/0 returns valid statuses" do
      assert :in_progress in Intake.IntakeResponse.statuses()
      assert :completed in Intake.IntakeResponse.statuses()
    end

    test "lead_times/0 returns valid lead times" do
      assert :short in Intake.IntakeResponse.lead_times()
      assert :medium in Intake.IntakeResponse.lead_times()
      assert :long in Intake.IntakeResponse.lead_times()
    end

    test "hours_per_day_options/0 returns valid options" do
      assert :under_10 in Intake.IntakeResponse.hours_per_day_options()
      assert :ten_to_thirty in Intake.IntakeResponse.hours_per_day_options()
      assert :over_thirty in Intake.IntakeResponse.hours_per_day_options()
    end

    test "intensities/0 returns valid intensities" do
      assert :low in Intake.IntakeResponse.intensities()
      assert :moderate in Intake.IntakeResponse.intensities()
      assert :high in Intake.IntakeResponse.intensities()
    end

    test "coaching_preferences/0 returns valid preferences" do
      assert :self_directed in Intake.IntakeResponse.coaching_preferences()
      assert :coach_guided in Intake.IntakeResponse.coaching_preferences()
    end
  end

  describe "IntakeResponse changesets" do
    test "create_changeset requires user_id" do
      changeset = Intake.IntakeResponse.create_changeset(%Intake.IntakeResponse{}, %{})
      assert %{user_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "preferences_changeset casts limitations and coaching_preference" do
      response = %Intake.IntakeResponse{}

      changeset =
        Intake.IntakeResponse.preferences_changeset(response, %{
          limitations: ["menopause"],
          limitations_notes: "Some notes",
          coaching_preference: :coach_guided
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :limitations) == ["menopause"]
      assert Ecto.Changeset.get_change(changeset, :coaching_preference) == :coach_guided
    end

    test "regimen_changeset casts fitness and personal dev fields" do
      response = %Intake.IntakeResponse{}

      changeset =
        Intake.IntakeResponse.regimen_changeset(response, %{
          fitness_regimen: :moderate,
          fitness_regimen_notes: "Yoga",
          personal_dev_regimen: :some,
          personal_dev_regimen_notes: "Reading"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :fitness_regimen) == :moderate
      assert Ecto.Changeset.get_change(changeset, :personal_dev_regimen) == :some
    end

    test "location_changeset casts location and feedback fields" do
      response = %Intake.IntakeResponse{}

      changeset =
        Intake.IntakeResponse.location_changeset(response, %{
          city: "Toronto",
          province: "Ontario",
          country: "Canada",
          feedback_interest: true
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :city) == "Toronto"
      assert Ecto.Changeset.get_change(changeset, :feedback_interest) == true
    end

    test "step_changeset rejects step less than 1" do
      response = %Intake.IntakeResponse{}
      changeset = Intake.IntakeResponse.step_changeset(response, %{current_step: 0})
      refute changeset.valid?
    end

    test "completion_changeset requires all mandatory fields" do
      response = %Intake.IntakeResponse{}
      changeset = Intake.IntakeResponse.completion_changeset(response, %{})
      refute changeset.valid?
      assert errors_on(changeset).goal_intent != []
      assert errors_on(changeset).goal_category_id != []
      assert errors_on(changeset).lead_time != []
      assert errors_on(changeset).days_per_week != []
      assert errors_on(changeset).hours_per_day != []
      assert errors_on(changeset).intensity != []
    end

    test "completion_changeset sets status and completed_at" do
      category = goal_category_fixture()

      response = %Intake.IntakeResponse{
        goal_intent: "My goal",
        goal_category_id: category.id,
        lead_time: :short,
        days_per_week: 3,
        hours_per_day: :ten_to_thirty,
        intensity: :moderate
      }

      changeset = Intake.IntakeResponse.completion_changeset(response, %{})
      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :status) == :completed
      assert Ecto.Changeset.get_change(changeset, :completed_at) != nil
    end
  end

  describe "complete_intake_response/1" do
    test "marks a fully-filled response as completed" do
      user = user_fixture()
      category = goal_category_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      {:ok, response} =
        Intake.update_intake_goal(response, %{
          goal_intent: "My goal",
          goal_category_id: category.id
        })

      {:ok, response} =
        Intake.update_intake_availability(response, %{
          lead_time: :short,
          days_per_week: 3,
          hours_per_day: :ten_to_thirty,
          intensity: :moderate
        })

      {:ok, completed} = Intake.complete_intake_response(response)
      assert completed.status == :completed
      assert completed.completed_at != nil
    end

    test "rejects completion when required fields are missing" do
      user = user_fixture()
      {:ok, response} = Intake.create_intake_response(user)

      {:error, changeset} = Intake.complete_intake_response(response)
      assert errors_on(changeset).goal_intent != []
    end
  end
end
