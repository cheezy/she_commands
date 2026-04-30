defmodule SheCommands.Feedback.FeedbackSurveyTest do
  use SheCommands.DataCase, async: true

  alias SheCommands.Feedback.FeedbackSurvey

  describe "survey_types/0" do
    test "returns the canonical list of survey types" do
      assert FeedbackSurvey.survey_types() == [:mid_plan_check, :post_plan_review]
    end
  end

  describe "create_changeset/2" do
    test "is invalid without plan_id, user_id, or survey_type" do
      changeset = FeedbackSurvey.create_changeset(%FeedbackSurvey{}, %{})
      refute changeset.valid?
      errors = errors_on(changeset)
      assert errors[:plan_id] != []
      assert errors[:user_id] != []
      assert errors[:survey_type] != []
    end

    test "rejects an unknown survey_type via the Ecto.Enum cast" do
      changeset =
        FeedbackSurvey.create_changeset(%FeedbackSurvey{}, %{
          plan_id: 1,
          user_id: 1,
          survey_type: :bogus
        })

      refute changeset.valid?
      assert errors_on(changeset).survey_type != []
    end

    test "accepts an optional pre-populated responses map and completed_at" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      changeset =
        FeedbackSurvey.create_changeset(%FeedbackSurvey{}, %{
          plan_id: 1,
          user_id: 1,
          survey_type: :mid_plan_check,
          responses: %{"q1" => "yes"},
          completed_at: now
        })

      assert changeset.valid?
      assert get_field(changeset, :responses) == %{"q1" => "yes"}
      assert get_field(changeset, :completed_at) == now
    end

    test "defaults responses to %{} when not supplied" do
      changeset =
        FeedbackSurvey.create_changeset(%FeedbackSurvey{}, %{
          plan_id: 1,
          user_id: 1,
          survey_type: :post_plan_review
        })

      assert changeset.valid?
      assert get_field(changeset, :responses) == %{}
    end
  end

  describe "complete_changeset/2" do
    test "stores the responses map and stamps completed_at" do
      before = DateTime.utc_now() |> DateTime.add(-1, :second)

      changeset =
        FeedbackSurvey.complete_changeset(%FeedbackSurvey{}, %{
          "q1" => "answer",
          "q2" => "5"
        })

      assert get_change(changeset, :responses) == %{"q1" => "answer", "q2" => "5"}

      completed_at = get_change(changeset, :completed_at)
      assert completed_at
      assert DateTime.compare(completed_at, before) in [:gt, :eq]
      assert completed_at == DateTime.truncate(completed_at, :second)
    end

    test "accepts an empty map" do
      changeset = FeedbackSurvey.complete_changeset(%FeedbackSurvey{}, %{})
      # cast/3 does not register a change when the new value matches the
      # default; that's fine — the schema default is %{} so the field
      # still resolves correctly.
      assert get_field(changeset, :responses) == %{}
      assert get_change(changeset, :completed_at)
    end

    test "raises FunctionClauseError when called with a non-map" do
      assert_raise FunctionClauseError, fn ->
        FeedbackSurvey.complete_changeset(%FeedbackSurvey{}, "not a map")
      end
    end
  end
end
