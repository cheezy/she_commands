defmodule SheCommands.Feedback.FeedbackPromptTest do
  use SheCommands.DataCase, async: true

  alias SheCommands.Feedback.FeedbackPrompt

  describe "prompt_types/0" do
    test "returns the canonical list of prompt types" do
      assert FeedbackPrompt.prompt_types() == [:mid_plan, :post_plan]
    end
  end

  describe "statuses/0" do
    test "returns the canonical lifecycle list" do
      assert FeedbackPrompt.statuses() == [:pending, :sent, :responded, :expired]
    end
  end

  describe "create_changeset/2" do
    test "is invalid without plan_id, user_id, or prompt_type" do
      changeset = FeedbackPrompt.create_changeset(%FeedbackPrompt{}, %{})
      refute changeset.valid?
      errors = errors_on(changeset)
      assert errors[:plan_id] != []
      assert errors[:user_id] != []
      assert errors[:prompt_type] != []
    end

    test "rejects an unknown prompt_type via the Ecto.Enum cast" do
      changeset =
        FeedbackPrompt.create_changeset(%FeedbackPrompt{}, %{
          plan_id: 1,
          user_id: 1,
          prompt_type: :bogus
        })

      refute changeset.valid?
      assert errors_on(changeset).prompt_type != []
    end

    test "accepts the optional :status and :scheduled_for fields" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      changeset =
        FeedbackPrompt.create_changeset(%FeedbackPrompt{}, %{
          plan_id: 1,
          user_id: 1,
          prompt_type: :mid_plan,
          status: :sent,
          scheduled_for: now
        })

      assert changeset.valid?
      assert get_field(changeset, :status) == :sent
      assert get_field(changeset, :scheduled_for) == now
    end

    test "defaults status to :pending when not supplied" do
      changeset =
        FeedbackPrompt.create_changeset(%FeedbackPrompt{}, %{
          plan_id: 1,
          user_id: 1,
          prompt_type: :post_plan
        })

      assert changeset.valid?
      assert get_field(changeset, :status) == :pending
    end

    test "ignores fields outside the cast list" do
      changeset =
        FeedbackPrompt.create_changeset(%FeedbackPrompt{}, %{
          plan_id: 1,
          user_id: 1,
          prompt_type: :mid_plan,
          response: "should not stick during create",
          responded_at: DateTime.utc_now()
        })

      assert get_field(changeset, :response) == nil
      assert get_field(changeset, :responded_at) == nil
    end
  end

  describe "mark_sent_changeset/1" do
    test "sets status to :sent and stamps sent_at to a recent UTC datetime" do
      before = DateTime.utc_now() |> DateTime.add(-1, :second)
      changeset = FeedbackPrompt.mark_sent_changeset(%FeedbackPrompt{status: :pending})

      assert get_change(changeset, :status) == :sent

      sent_at = get_change(changeset, :sent_at)
      assert sent_at
      assert DateTime.compare(sent_at, before) in [:gt, :eq]
      assert sent_at == DateTime.truncate(sent_at, :second)
    end
  end

  describe "mark_responded_changeset/2" do
    test "stores the response, stamps responded_at, and sets status to :responded" do
      changeset =
        FeedbackPrompt.mark_responded_changeset(%FeedbackPrompt{status: :sent}, "Yes")

      assert changeset.valid?
      assert get_change(changeset, :response) == "Yes"
      assert get_change(changeset, :status) == :responded
      assert get_change(changeset, :responded_at)
    end

    test "is invalid when response is nil" do
      changeset = FeedbackPrompt.mark_responded_changeset(%FeedbackPrompt{}, nil)
      refute changeset.valid?
      assert errors_on(changeset).response != []
    end

    test "is invalid when response is an empty string" do
      changeset = FeedbackPrompt.mark_responded_changeset(%FeedbackPrompt{}, "")
      refute changeset.valid?
      assert errors_on(changeset).response != []
    end
  end

  describe "mark_expired_changeset/1" do
    test "sets status to :expired without touching response or responded_at" do
      changeset = FeedbackPrompt.mark_expired_changeset(%FeedbackPrompt{status: :pending})
      assert get_change(changeset, :status) == :expired
      refute Map.has_key?(changeset.changes, :response)
      refute Map.has_key?(changeset.changes, :responded_at)
    end
  end
end
