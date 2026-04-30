defmodule SheCommandsWeb.CoachLive.EscalationShow do
  @moduledoc """
  Coach detail view for a single escalation.

  Shows the user's profile, the active plan summary grouped by Power
  Pillar, a chat-context excerpt around the flagged message (if any),
  and a response form. Submitting the response transitions the
  escalation to :responded and broadcasts via PubSub.

  Authorization: only the assigned coach (or any admin) can view or
  respond. Other roles are redirected to the queue.
  """

  use SheCommandsWeb, :live_view

  alias SheCommands.Chat
  alias SheCommands.Escalations

  @chat_context_window 2

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    escalation = Escalations.get_escalation_with_context!(id)
    user = socket.assigns.current_scope.user

    if authorized?(escalation, user) do
      {:ok,
       socket
       |> assign(:page_title, gettext("Escalation"))
       |> assign(:escalation, escalation)
       |> assign(:modules_by_pillar, modules_by_pillar(escalation.plan))
       |> assign(:chat_context, chat_context(escalation))
       |> assign(:response_text, escalation.coach_response || "")}
    else
      {:ok,
       socket
       |> put_flash(:error, gettext("This escalation is assigned to another coach."))
       |> redirect(to: ~p"/coach/escalations")}
    end
  end

  @impl true
  def handle_event("submit_response", %{"response" => response}, socket) do
    response = String.trim(response)
    escalation = socket.assigns.escalation
    user = socket.assigns.current_scope.user

    cond do
      not authorized?(escalation, user) ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("This escalation is assigned to another coach."))
         |> redirect(to: ~p"/coach/escalations")}

      response == "" ->
        {:noreply,
         put_flash(socket, :error, gettext("Please enter a response before submitting."))}

      true ->
        {:ok, updated} = Escalations.respond_to_escalation(escalation, response)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Response sent."))
         |> assign(:escalation, Escalations.get_escalation_with_context!(updated.id))
         |> assign(:response_text, response)}
    end
  end

  defp authorized?(escalation, user) do
    user.role == :admin or escalation.coach_id == user.id
  end

  defp modules_by_pillar(nil), do: %{}

  defp modules_by_pillar(plan) do
    plan.plan_modules
    |> Enum.group_by(& &1.power_pillar)
    |> Map.new(fn {pillar, plan_modules} ->
      modules = Enum.map(plan_modules, & &1.module)
      {pillar, modules}
    end)
  end

  defp chat_context(%{chat_message: nil}), do: []

  defp chat_context(%{chat_message: chat_message}) when not is_nil(chat_message) do
    plan_id = chat_message.plan_id
    user_id = chat_message.user_id
    messages = Chat.list_messages_for_plan(plan_id, user_id)

    case Enum.find_index(messages, &(&1.id == chat_message.id)) do
      nil ->
        [chat_message]

      index ->
        first = max(index - @chat_context_window, 0)
        last = min(index + @chat_context_window, length(messages) - 1)
        Enum.slice(messages, first..last)
    end
  end

  def display_name(user) do
    cond do
      user.display_name && user.display_name != "" -> user.display_name
      user.name && user.name != "" -> user.name
      true -> gettext("Member")
    end
  end

  def location(user) do
    [user.city, user.province, user.country]
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.join(", ")
  end

  def subject_label(:plan_clarification), do: gettext("Plan clarification")
  def subject_label(:motivation_support), do: gettext("Motivation support")
  def subject_label(:event_prioritization), do: gettext("Event prioritization")

  def status_label(:pending), do: gettext("Pending")
  def status_label(:in_review), do: gettext("In review")
  def status_label(:responded), do: gettext("Responded")
  def status_label(:closed), do: gettext("Closed")

  def pillar_label(:power_up), do: gettext("Power Up")
  def pillar_label(:power_through), do: gettext("Power Through")
  def pillar_label(:power_down), do: gettext("Power Down")
  def pillar_label(:empower), do: gettext("Empower")

  def pillar_label(other) when is_atom(other),
    do: other |> Atom.to_string() |> String.capitalize()
end
