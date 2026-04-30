defmodule SheCommands.Escalations.EscalationTest do
  use SheCommands.DataCase, async: true

  alias SheCommands.Escalations.Escalation

  describe "statuses/0" do
    test "returns the canonical lifecycle list" do
      assert Escalation.statuses() == [:pending, :in_review, :responded, :closed]
    end
  end

  describe "subjects/0" do
    test "returns the canonical subject list" do
      assert Escalation.subjects() ==
               [:plan_clarification, :motivation_support, :event_prioritization]
    end
  end

  describe "create_changeset/2" do
    test "is invalid without user_id, subject, or sla_deadline" do
      changeset = Escalation.create_changeset(%Escalation{}, %{})
      refute changeset.valid?
      errors = errors_on(changeset)
      assert errors[:user_id] != []
      assert errors[:subject] != []
      assert errors[:sla_deadline] != []
    end

    test "rejects an unknown subject via the Ecto.Enum cast" do
      changeset =
        Escalation.create_changeset(%Escalation{}, %{
          user_id: 1,
          subject: :bogus,
          sla_deadline: DateTime.utc_now()
        })

      refute changeset.valid?
      assert errors_on(changeset).subject != []
    end

    test "accepts a valid subject and the optional plan_id, chat_message_id, user_note" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      changeset =
        Escalation.create_changeset(%Escalation{}, %{
          user_id: 1,
          subject: :plan_clarification,
          sla_deadline: now,
          plan_id: 7,
          chat_message_id: 42,
          user_note: "Need help"
        })

      assert changeset.valid?
      assert get_field(changeset, :plan_id) == 7
      assert get_field(changeset, :chat_message_id) == 42
      assert get_field(changeset, :user_note) == "Need help"
    end

    test "defaults status to :pending when not supplied" do
      changeset =
        Escalation.create_changeset(%Escalation{}, %{
          user_id: 1,
          subject: :motivation_support,
          sla_deadline: DateTime.utc_now()
        })

      assert changeset.valid?
      assert get_field(changeset, :status) == :pending
    end

    test "honors :status when explicitly supplied" do
      changeset =
        Escalation.create_changeset(%Escalation{}, %{
          user_id: 1,
          subject: :event_prioritization,
          sla_deadline: DateTime.utc_now(),
          status: :in_review
        })

      assert changeset.valid?
      assert get_field(changeset, :status) == :in_review
    end

    test "ignores fields outside the cast list" do
      changeset =
        Escalation.create_changeset(%Escalation{}, %{
          user_id: 1,
          subject: :plan_clarification,
          sla_deadline: DateTime.utc_now(),
          coach_id: 99,
          coach_response: "leak attempt",
          responded_at: DateTime.utc_now()
        })

      assert get_field(changeset, :coach_id) == nil
      assert get_field(changeset, :coach_response) == nil
      assert get_field(changeset, :responded_at) == nil
    end
  end

  describe "assign_coach_changeset/2" do
    test "requires coach_id and transitions status to :in_review" do
      changeset = Escalation.assign_coach_changeset(%Escalation{status: :pending}, %{})
      refute changeset.valid?
      assert errors_on(changeset).coach_id != []
    end

    test "is valid with coach_id and forces status to :in_review" do
      changeset =
        Escalation.assign_coach_changeset(
          %Escalation{status: :pending},
          %{coach_id: 5}
        )

      assert changeset.valid?
      assert get_change(changeset, :coach_id) == 5
      assert get_change(changeset, :status) == :in_review
    end

    test "still forces :in_review even if a different status is passed in" do
      # cast/3 only allows :coach_id; an extra :status key is ignored
      # and our put_change always wins.
      changeset =
        Escalation.assign_coach_changeset(
          %Escalation{status: :pending},
          %{coach_id: 5, status: :closed}
        )

      assert get_change(changeset, :status) == :in_review
    end
  end

  describe "respond_changeset/2" do
    test "requires coach_response" do
      changeset = Escalation.respond_changeset(%Escalation{status: :in_review}, %{})
      refute changeset.valid?
      assert errors_on(changeset).coach_response != []
    end

    test "rejects an empty string coach_response" do
      changeset =
        Escalation.respond_changeset(%Escalation{}, %{coach_response: ""})

      refute changeset.valid?
      assert errors_on(changeset).coach_response != []
    end

    test "stores the response, sets status :responded, and stamps responded_at" do
      before = DateTime.utc_now() |> DateTime.add(-1, :second)

      changeset =
        Escalation.respond_changeset(%Escalation{status: :in_review}, %{
          coach_response: "Here's how to think about it"
        })

      assert changeset.valid?
      assert get_change(changeset, :coach_response) == "Here's how to think about it"
      assert get_change(changeset, :status) == :responded

      responded_at = get_change(changeset, :responded_at)
      assert responded_at
      assert DateTime.compare(responded_at, before) in [:gt, :eq]
      assert responded_at == DateTime.truncate(responded_at, :second)
    end
  end

  describe "close_changeset/1" do
    test "sets status to :closed without touching coach_response or responded_at" do
      changeset = Escalation.close_changeset(%Escalation{status: :responded})
      assert get_change(changeset, :status) == :closed
      refute Map.has_key?(changeset.changes, :coach_response)
      refute Map.has_key?(changeset.changes, :responded_at)
    end

    test "is callable from any prior status" do
      Enum.each([:pending, :in_review, :responded], fn status ->
        changeset = Escalation.close_changeset(%Escalation{status: status})
        assert get_change(changeset, :status) == :closed
      end)
    end
  end
end
