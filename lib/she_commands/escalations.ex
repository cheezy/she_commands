defmodule SheCommands.Escalations do
  @moduledoc """
  The Escalations context.

  Manages member-to-coach escalations: creation with SLA tracking,
  coach assignment, response, closure, and capacity reporting.
  """

  import Ecto.Query, warn: false

  alias Phoenix.PubSub
  alias SheCommands.Accounts
  alias SheCommands.Accounts.Scope
  alias SheCommands.Accounts.UserNotifier
  alias SheCommands.Escalations.Escalation
  alias SheCommands.Repo

  @sla_business_hours 48
  @pubsub SheCommands.PubSub
  @pending_topic "escalations:pending"

  @doc """
  Subscribes the calling process to escalation events for a single user.

  Receives `{:escalation_updated, %Escalation{}}` messages whenever any
  escalation belonging to that user is created, assigned, responded to,
  or closed.
  """
  def subscribe_user(user_id) do
    PubSub.subscribe(@pubsub, user_topic(user_id))
  end

  @doc """
  Subscribes the calling process to changes in the pending escalations
  queue (used by the coach dashboard).

  Receives `{:pending_changed, %Escalation{}}` whenever an escalation is
  created (new pending) or transitions out of :pending (claim/respond/close).
  """
  def subscribe_pending do
    PubSub.subscribe(@pubsub, @pending_topic)
  end

  defp user_topic(user_id), do: "escalations:user:#{user_id}"

  defp broadcast(%Escalation{} = escalation) do
    PubSub.broadcast(@pubsub, user_topic(escalation.user_id), {:escalation_updated, escalation})
    PubSub.broadcast(@pubsub, @pending_topic, {:pending_changed, escalation})
    escalation
  end

  @doc """
  Creates an escalation for the given scope's user, computing the SLA
  deadline at 48 business hours (weekdays only) from now.
  """
  def create_escalation(%Scope{user: user}, attrs) do
    if capacity_blocks?(user) do
      {:error, :at_capacity}
    else
      now = DateTime.truncate(DateTime.utc_now(), :second)
      sla_deadline = add_business_hours(now, @sla_business_hours)

      attrs =
        attrs
        |> Map.put(:user_id, user.id)
        |> Map.put(:sla_deadline, sla_deadline)

      case %Escalation{} |> Escalation.create_changeset(attrs) |> Repo.insert() do
        {:ok, escalation} ->
          notify_coaches_and_member(escalation, user)
          {:ok, broadcast(escalation)}

        other ->
          other
      end
    end
  end

  # Capacity blocks a user only when (a) capacity is full and (b) the
  # user is not already an active client. Existing active clients can
  # always add more escalations because their count does not increase
  # the active-client headcount.
  defp capacity_blocks?(user) do
    at_capacity?() and not has_open_escalation?(user.id)
  end

  defp has_open_escalation?(user_id) do
    Escalation
    |> where([e], e.user_id == ^user_id and e.status != :closed)
    |> Repo.exists?()
  end

  @doc """
  Returns true when the number of distinct users with open escalations
  is at or above the configured Command Centre capacity cap.
  """
  def at_capacity? do
    cap = Application.get_env(:she_commands, :escalation_capacity_cap, 50)
    active_client_count() >= cap
  end

  @doc """
  Returns escalations whose SLA deadline has passed and that are still
  awaiting completion (pending or in_review), oldest deadline first.
  """
  def list_overdue_escalations do
    now = DateTime.utc_now()

    Escalation
    |> where([e], e.status in [:pending, :in_review] and e.sla_deadline < ^now)
    |> order_by([e], asc: e.sla_deadline, asc: e.id)
    |> Repo.all()
  end

  @doc """
  Returns escalation counts for the coach dashboard:
  `%{pending: N, in_review: N, overdue: N}`. Overdue counts the
  pending+in_review escalations whose SLA has passed.
  """
  def dashboard_metrics do
    now = DateTime.utc_now()

    rows =
      Escalation
      |> where([e], e.status in [:pending, :in_review])
      |> select([e], {e.status, e.sla_deadline})
      |> Repo.all()

    Enum.reduce(rows, %{pending: 0, in_review: 0, overdue: 0}, fn {status, deadline}, acc ->
      acc = Map.update!(acc, status, &(&1 + 1))

      if DateTime.compare(deadline, now) == :lt,
        do: Map.update!(acc, :overdue, &(&1 + 1)),
        else: acc
    end)
  end

  defp notify_coaches_and_member(%Escalation{} = escalation, member) do
    escalation_with_user = %{escalation | user: member}
    dashboard_url = SheCommandsWeb.Endpoint.url() <> "/coach/escalations"

    Accounts.list_coaches()
    |> Enum.reject(&(&1.id == member.id))
    |> Enum.each(fn coach ->
      try do
        UserNotifier.deliver_new_escalation_notification(
          coach,
          escalation_with_user,
          dashboard_url
        )
      rescue
        _ -> :ok
      end
    end)

    try do
      UserNotifier.deliver_escalation_confirmation(member, escalation)
    rescue
      _ -> :ok
    end

    :ok
  end

  @doc """
  Returns pending escalations ordered by oldest first (for SLA triage).
  """
  def list_pending_escalations do
    Escalation
    |> where([e], e.status == :pending)
    |> order_by([e], asc: e.sla_deadline, asc: e.id)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @doc """
  Returns escalations for the user in the given scope, newest first.
  """
  def list_escalations_for_user(%Scope{user: user}, _opts \\ []) do
    Escalation
    |> where([e], e.user_id == ^user.id)
    |> order_by([e], desc: e.inserted_at, desc: e.id)
    |> Repo.all()
  end

  @doc """
  Fetches an escalation by id, raising if not found.
  """
  def get_escalation!(id), do: Repo.get!(Escalation, id)

  @doc """
  Fetches an escalation with the user, plan (with goal_category and
  modules), and chat_message preloaded — everything the coach detail
  view needs.
  """
  def get_escalation_with_context!(id) do
    Escalation
    |> Repo.get!(id)
    |> Repo.preload([
      :user,
      :chat_message,
      plan: [:goal_category, plan_modules: :module]
    ])
  end

  @doc """
  Assigns a coach to an escalation and transitions it to :in_review.
  """
  def assign_coach(%Escalation{} = escalation, coach_id) do
    escalation
    |> Escalation.assign_coach_changeset(%{coach_id: coach_id})
    |> Repo.update()
    |> tap_broadcast()
  end

  @doc """
  Records a coach response and transitions the escalation to :responded.
  """
  def respond_to_escalation(%Escalation{} = escalation, response) do
    result =
      escalation
      |> Escalation.respond_changeset(%{coach_response: response})
      |> Repo.update()
      |> tap_broadcast()

    notify_member_of_response(result)
    result
  end

  defp notify_member_of_response({:ok, escalation}) do
    member = Repo.preload(escalation, :user).user

    try do
      UserNotifier.deliver_coach_response_notification(member, escalation)
    rescue
      _ -> :ok
    end
  end

  defp notify_member_of_response(_), do: :ok

  @doc """
  Closes an escalation.
  """
  def close_escalation(%Escalation{} = escalation) do
    escalation
    |> Escalation.close_changeset()
    |> Repo.update()
    |> tap_broadcast()
  end

  defp tap_broadcast({:ok, escalation}), do: {:ok, broadcast(escalation)}
  defp tap_broadcast(other), do: other

  @doc """
  Counts the distinct users with at least one open (non-closed) escalation.
  """
  def active_client_count do
    Escalation
    |> where([e], e.status != :closed)
    |> distinct([e], e.user_id)
    |> select([e], e.user_id)
    |> Repo.all()
    |> length()
  end

  @doc """
  Returns true when the coach has reached the configured capacity of
  open (non-closed) escalations.
  """
  def coach_at_capacity?(coach_id) do
    cap = Application.get_env(:she_commands, :coach_capacity, 10)

    open =
      Escalation
      |> where([e], e.coach_id == ^coach_id and e.status != :closed)
      |> Repo.aggregate(:count, :id)

    open >= cap
  end

  @doc """
  Adds the given number of business hours (weekdays only) to a UTC datetime.

  Time is added one hour at a time; hours that land on a Saturday or Sunday
  do not count toward the total. This implements the "skip weekends" SLA
  rule: a Friday escalation's 48-hour SLA lands on the following Tuesday at
  the same time of day.
  """
  def add_business_hours(%DateTime{} = datetime, hours) when is_integer(hours) and hours >= 0 do
    do_add_business_hours(datetime, hours)
  end

  defp do_add_business_hours(datetime, 0), do: datetime

  defp do_add_business_hours(datetime, hours) do
    next = DateTime.add(datetime, 3600, :second)

    if weekday?(next) do
      do_add_business_hours(next, hours - 1)
    else
      do_add_business_hours(next, hours)
    end
  end

  defp weekday?(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.day_of_week()
    |> Kernel.<=(5)
  end
end
