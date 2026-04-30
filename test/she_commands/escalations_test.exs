defmodule SheCommands.EscalationsTest do
  use SheCommands.DataCase

  import SheCommands.AccountsFixtures
  import SheCommands.EscalationsFixtures

  alias SheCommands.Accounts.Scope
  alias SheCommands.Escalations
  alias SheCommands.Escalations.Escalation

  describe "create_escalation/2" do
    test "creates a pending escalation with calculated SLA deadline" do
      user = user_fixture(%{})
      scope = Scope.for_user(user)

      assert {:ok, %Escalation{} = escalation} =
               Escalations.create_escalation(scope, %{
                 subject: :plan_clarification,
                 user_note: "Help"
               })

      assert escalation.user_id == user.id
      assert escalation.status == :pending
      assert escalation.subject == :plan_clarification
      assert escalation.sla_deadline
      assert DateTime.compare(escalation.sla_deadline, DateTime.utc_now()) == :gt
    end

    test "returns error changeset when subject is missing" do
      user = user_fixture(%{})
      scope = Scope.for_user(user)

      assert {:error, changeset} = Escalations.create_escalation(scope, %{user_note: "Help"})
      assert errors_on(changeset).subject != []
    end
  end

  describe "list_pending_escalations/0" do
    test "returns only pending escalations ordered by oldest first" do
      first = escalation_fixture()
      _newer = escalation_fixture()

      {:ok, in_review} = Escalations.assign_coach(escalation_fixture(), coach_fixture().id)
      assert in_review.status == :in_review

      pending_ids = Enum.map(Escalations.list_pending_escalations(), & &1.id)

      assert hd(pending_ids) == first.id
      refute in_review.id in pending_ids
      assert length(pending_ids) == 2
    end
  end

  describe "list_escalations_for_user/2" do
    test "returns only the scoped user's escalations, newest first" do
      user_a = user_fixture(%{})
      user_b = user_fixture(%{})

      _other = escalation_fixture(%{user: user_b})
      first = escalation_fixture(%{user: user_a})
      second = escalation_fixture(%{user: user_a})

      ids =
        user_a
        |> Scope.for_user()
        |> Escalations.list_escalations_for_user()
        |> Enum.map(& &1.id)

      assert ids == [second.id, first.id]
    end
  end

  describe "get_escalation!/1" do
    test "returns the escalation by id" do
      escalation = escalation_fixture()
      assert Escalations.get_escalation!(escalation.id).id == escalation.id
    end

    test "raises when not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Escalations.get_escalation!(-1)
      end
    end
  end

  describe "assign_coach/2" do
    test "sets coach_id and transitions to :in_review" do
      escalation = escalation_fixture()
      coach = coach_fixture()

      assert {:ok, updated} = Escalations.assign_coach(escalation, coach.id)
      assert updated.coach_id == coach.id
      assert updated.status == :in_review
    end
  end

  describe "respond_to_escalation/2" do
    test "sets coach_response, responded_at, and transitions to :responded" do
      escalation = escalation_fixture()

      assert {:ok, updated} = Escalations.respond_to_escalation(escalation, "Here is help.")
      assert updated.coach_response == "Here is help."
      assert updated.status == :responded
      assert updated.responded_at
    end

    test "returns error changeset when coach_response is missing" do
      escalation = escalation_fixture()
      assert {:error, changeset} = Escalations.respond_to_escalation(escalation, nil)
      assert errors_on(changeset).coach_response != []
    end
  end

  describe "close_escalation/1" do
    test "transitions to :closed" do
      escalation = escalation_fixture()
      assert {:ok, updated} = Escalations.close_escalation(escalation)
      assert updated.status == :closed
    end
  end

  describe "active_client_count/0" do
    test "counts distinct users with non-closed escalations" do
      user_a = user_fixture(%{})
      user_b = user_fixture(%{})
      user_c = user_fixture(%{})

      escalation_fixture(%{user: user_a})
      escalation_fixture(%{user: user_a})
      escalation_fixture(%{user: user_b})

      closed = escalation_fixture(%{user: user_c})
      {:ok, _} = Escalations.close_escalation(closed)

      assert Escalations.active_client_count() == 2
    end
  end

  describe "coach_at_capacity?/1" do
    test "returns false below capacity" do
      coach = coach_fixture()
      Application.put_env(:she_commands, :coach_capacity, 5)

      for _ <- 1..3 do
        {:ok, _} = Escalations.assign_coach(escalation_fixture(), coach.id)
      end

      refute Escalations.coach_at_capacity?(coach.id)
    after
      Application.put_env(:she_commands, :coach_capacity, 10)
    end

    test "returns true once the cap is reached" do
      coach = coach_fixture()
      Application.put_env(:she_commands, :coach_capacity, 2)

      for _ <- 1..2 do
        {:ok, _} = Escalations.assign_coach(escalation_fixture(), coach.id)
      end

      assert Escalations.coach_at_capacity?(coach.id)
    after
      Application.put_env(:she_commands, :coach_capacity, 10)
    end

    test "closed escalations do not count toward capacity" do
      coach = coach_fixture()
      Application.put_env(:she_commands, :coach_capacity, 2)

      {:ok, escalation} = Escalations.assign_coach(escalation_fixture(), coach.id)
      {:ok, _} = Escalations.close_escalation(escalation)
      {:ok, _} = Escalations.assign_coach(escalation_fixture(), coach.id)

      refute Escalations.coach_at_capacity?(coach.id)
    after
      Application.put_env(:she_commands, :coach_capacity, 10)
    end
  end

  describe "add_business_hours/2 (SLA calculation)" do
    test "Friday 4pm + 48 business hours lands on Tuesday 4pm" do
      # 2026-05-01 is a Friday
      friday = DateTime.new!(~D[2026-05-01], ~T[16:00:00], "Etc/UTC")
      result = Escalations.add_business_hours(friday, 48)

      assert DateTime.to_date(result) == ~D[2026-05-05]
      assert DateTime.to_time(result) == ~T[16:00:00]
    end

    test "Monday 10am + 48 business hours lands on Wednesday 10am" do
      monday = DateTime.new!(~D[2026-05-04], ~T[10:00:00], "Etc/UTC")
      result = Escalations.add_business_hours(monday, 48)

      assert DateTime.to_date(result) == ~D[2026-05-06]
      assert DateTime.to_time(result) == ~T[10:00:00]
    end

    test "Tuesday 4pm + 48 business hours lands on Thursday 4pm (no weekend in window)" do
      tuesday = DateTime.new!(~D[2026-05-05], ~T[16:00:00], "Etc/UTC")
      result = Escalations.add_business_hours(tuesday, 48)

      assert DateTime.to_date(result) == ~D[2026-05-07]
      assert DateTime.to_time(result) == ~T[16:00:00]
    end

    test "0 business hours returns the same datetime" do
      dt = DateTime.new!(~D[2026-05-04], ~T[10:00:00], "Etc/UTC")
      assert Escalations.add_business_hours(dt, 0) == dt
    end
  end

  describe "at_capacity?/0 and create_escalation capacity gate" do
    test "returns false below cap and allows creation" do
      Application.put_env(:she_commands, :escalation_capacity_cap, 5)

      refute Escalations.at_capacity?()

      user = user_fixture(%{})

      assert {:ok, _} =
               user
               |> Scope.for_user()
               |> Escalations.create_escalation(%{subject: :plan_clarification})
    after
      Application.put_env(:she_commands, :escalation_capacity_cap, 50)
    end

    test "returns true at the cap and blocks new creations" do
      Application.put_env(:she_commands, :escalation_capacity_cap, 1)

      _existing = escalation_fixture()

      assert Escalations.at_capacity?()

      newcomer = user_fixture(%{})

      assert {:error, :at_capacity} =
               newcomer
               |> Scope.for_user()
               |> Escalations.create_escalation(%{subject: :plan_clarification})
    after
      Application.put_env(:she_commands, :escalation_capacity_cap, 50)
    end

    test "multiple escalations from the same user count as one active client" do
      Application.put_env(:she_commands, :escalation_capacity_cap, 1)

      user = user_fixture(%{})
      escalation_fixture(%{user: user})
      escalation_fixture(%{user: user})

      # Same user has two escalations but counts as 1 — capacity full at 1
      assert Escalations.at_capacity?()

      assert {:ok, _} =
               user
               |> Scope.for_user()
               |> Escalations.create_escalation(%{subject: :motivation_support})
    after
      Application.put_env(:she_commands, :escalation_capacity_cap, 50)
    end

    test "cap of 0 blocks all new escalations" do
      Application.put_env(:she_commands, :escalation_capacity_cap, 0)
      assert Escalations.at_capacity?()

      user = user_fixture(%{})

      assert {:error, :at_capacity} =
               user
               |> Scope.for_user()
               |> Escalations.create_escalation(%{subject: :plan_clarification})
    after
      Application.put_env(:she_commands, :escalation_capacity_cap, 50)
    end
  end

  describe "list_overdue_escalations/0" do
    test "returns pending escalations past their SLA deadline" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      past = DateTime.add(now, -3600, :second)

      overdue = escalation_fixture()
      Ecto.Changeset.change(overdue, %{sla_deadline: past}) |> SheCommands.Repo.update!()

      _on_time = escalation_fixture()

      ids = Escalations.list_overdue_escalations() |> Enum.map(& &1.id)
      assert ids == [overdue.id]
    end

    test "includes in_review escalations whose SLA passed" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      past = DateTime.add(now, -3600, :second)
      coach = coach_fixture()

      escalation = escalation_fixture()
      {:ok, escalation} = Escalations.assign_coach(escalation, coach.id)
      Ecto.Changeset.change(escalation, %{sla_deadline: past}) |> SheCommands.Repo.update!()

      ids = Escalations.list_overdue_escalations() |> Enum.map(& &1.id)
      assert escalation.id in ids
    end

    test "excludes responded and closed escalations" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      past = DateTime.add(now, -3600, :second)

      escalation = escalation_fixture()
      Ecto.Changeset.change(escalation, %{sla_deadline: past}) |> SheCommands.Repo.update!()
      {:ok, escalation} = Escalations.respond_to_escalation(escalation, "Done.")
      {:ok, _} = Escalations.close_escalation(escalation)

      assert Escalations.list_overdue_escalations() == []
    end
  end

  describe "dashboard_metrics/0" do
    test "counts pending, in_review, and overdue separately" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      past = DateTime.add(now, -3600, :second)
      coach = coach_fixture()

      _pending_a = escalation_fixture()
      _pending_b = escalation_fixture()

      reviewing = escalation_fixture()
      {:ok, _} = Escalations.assign_coach(reviewing, coach.id)

      overdue = escalation_fixture()
      Ecto.Changeset.change(overdue, %{sla_deadline: past}) |> SheCommands.Repo.update!()

      assert %{pending: pending, in_review: in_review, overdue: overdue_count} =
               Escalations.dashboard_metrics()

      assert pending == 3
      assert in_review == 1
      assert overdue_count == 1
    end
  end

  describe "respond_to_escalation/2 notification" do
    test "sends a coach response notification email to the member" do
      user = user_fixture(%{})
      escalation = escalation_fixture(%{user: user, subject: :plan_clarification})

      {:ok, _} = Escalations.respond_to_escalation(escalation, "Try slowing down at step 3.")

      member_to = [{"", user.email}]

      assert_received {:email,
                       %{
                         to: ^member_to,
                         subject: "Your coach has responded: Plan clarification"
                       }}
    end
  end

  describe "lifecycle integration" do
    test "create -> assign -> respond -> close" do
      user = user_fixture(%{})
      coach = coach_fixture()
      scope = Scope.for_user(user)

      assert {:ok, escalation} =
               Escalations.create_escalation(scope, %{
                 subject: :motivation_support,
                 user_note: "I'm not seeing progress"
               })

      assert escalation.status == :pending

      assert {:ok, escalation} = Escalations.assign_coach(escalation, coach.id)
      assert escalation.status == :in_review

      assert {:ok, escalation} = Escalations.respond_to_escalation(escalation, "Let's adjust")
      assert escalation.status == :responded

      assert {:ok, escalation} = Escalations.close_escalation(escalation)
      assert escalation.status == :closed
    end
  end
end
