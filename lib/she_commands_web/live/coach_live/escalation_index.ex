defmodule SheCommandsWeb.CoachLive.EscalationIndex do
  @moduledoc """
  Coach dashboard listing pending escalations ordered by SLA urgency.

  Coaches can claim an escalation, which assigns them as the responder and
  transitions the escalation to :in_review (removing it from the queue).
  Subscribes to the queue PubSub topic for real-time updates as new
  escalations arrive or peer coaches claim items.
  """

  use SheCommandsWeb, :live_view

  alias SheCommands.Escalations

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Escalations.subscribe_pending()
    end

    {:ok,
     socket
     |> assign(:page_title, gettext("Escalations queue"))
     |> assign_pending()
     |> assign_metrics()}
  end

  @impl true
  def handle_event("claim", %{"id" => id}, socket) do
    coach_id = socket.assigns.current_scope.user.id

    {:ok, _updated} =
      id
      |> Escalations.get_escalation!()
      |> Escalations.assign_coach(coach_id)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Escalation claimed."))
     |> assign_pending()
     |> assign_metrics()}
  end

  @impl true
  def handle_info({:pending_changed, _escalation}, socket) do
    {:noreply,
     socket
     |> assign_pending()
     |> assign_metrics()}
  end

  defp assign_metrics(socket) do
    assign(socket, :metrics, Escalations.dashboard_metrics())
  end

  defp assign_pending(socket) do
    pending = Escalations.list_pending_escalations()
    now = DateTime.utc_now()

    rows =
      Enum.map(pending, fn escalation ->
        Map.put(escalation, :urgency, sla_urgency(escalation.sla_deadline, now))
      end)

    assign(socket, :pending, rows)
  end

  @doc """
  Returns the SLA urgency tier for a deadline relative to `now`.

  Tiers: :overdue (deadline passed), :red (<12 hours), :yellow (12-24h),
  :green (>24h).
  """
  def sla_urgency(%DateTime{} = deadline, %DateTime{} = now) do
    seconds_remaining = DateTime.diff(deadline, now)

    cond do
      seconds_remaining < 0 -> :overdue
      seconds_remaining < 12 * 3600 -> :red
      seconds_remaining < 24 * 3600 -> :yellow
      true -> :green
    end
  end

  @doc """
  Renders a humanized "X minutes/hours/days" string for the given
  number of seconds. Negative values are formatted as "overdue".
  """
  def humanize_remaining(seconds) when seconds < 0, do: gettext("overdue")
  def humanize_remaining(seconds) when seconds < 3600, do: gettext("under 1 hour")

  def humanize_remaining(seconds) when seconds < 86_400 do
    hours = div(seconds, 3600)
    gettext("%{count} hours", count: hours)
  end

  def humanize_remaining(seconds) do
    days = div(seconds, 86_400)
    gettext("%{count} days", count: days)
  end

  def display_name(user) do
    cond do
      user && user.display_name && user.display_name != "" -> user.display_name
      user && user.name && user.name != "" -> user.name
      true -> gettext("Member")
    end
  end

  def time_since(%DateTime{} = inserted_at, %DateTime{} = now) do
    seconds = DateTime.diff(now, inserted_at)

    cond do
      seconds < 60 -> gettext("just now")
      seconds < 3600 -> gettext("%{count} minutes ago", count: div(seconds, 60))
      seconds < 86_400 -> gettext("%{count} hours ago", count: div(seconds, 3600))
      true -> gettext("%{count} days ago", count: div(seconds, 86_400))
    end
  end

  def subject_label(:plan_clarification), do: gettext("Plan clarification")
  def subject_label(:motivation_support), do: gettext("Motivation support")
  def subject_label(:event_prioritization), do: gettext("Event prioritization")
end
