defmodule SheCommandsWeb.PlanLive.Show do
  use SheCommandsWeb, :live_view

  alias SheCommands.Chat
  alias SheCommands.Plans

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    plan = Plans.get_active_plan_for_user(user.id)

    if plan do
      {:ok,
       socket
       |> assign(:page_title, gettext("My Plan"))
       |> assign(:plan, plan)
       |> assign(:modules_by_pillar, group_by_pillar(plan.plan_modules))
       |> assign(:chat_open, false)
       |> assign(:chat_messages, [])
       |> assign(:chat_loading, false)}
    else
      {:ok,
       socket
       |> put_flash(:info, gettext("Complete your intake to generate a plan."))
       |> redirect(to: ~p"/intake")}
    end
  end

  @impl true
  def handle_event("toggle_chat", _params, socket) do
    open = !socket.assigns.chat_open
    socket = assign(socket, :chat_open, open)

    socket =
      if open && socket.assigns.chat_messages == [] do
        messages =
          Chat.list_messages_for_plan(
            socket.assigns.plan.id,
            socket.assigns.current_scope.user.id
          )

        assign(socket, :chat_messages, messages)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("send_message", %{"message" => content}, socket)
      when content != "" do
    user = socket.assigns.current_scope.user
    plan = socket.assigns.plan
    trimmed = String.trim(content)

    if trimmed != "" do
      case Chat.create_message(%{
             user_id: user.id,
             plan_id: plan.id,
             role: :user,
             content: trimmed
           }) do
        {:ok, user_msg} ->
          {:noreply, assign(socket, :chat_messages, socket.assigns.chat_messages ++ [user_msg])}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to send message."))}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("send_message", _params, socket), do: {:noreply, socket}

  def handle_event("suggest_question", %{"question" => question}, socket) do
    handle_event("send_message", %{"message" => question}, socket)
  end

  def handle_event("clear_chat", _params, socket) do
    Chat.clear_conversation(
      socket.assigns.plan.id,
      socket.assigns.current_scope.user.id
    )

    {:noreply, assign(socket, :chat_messages, [])}
  end

  @impl true
  def handle_info({:set_chat_loading, loading}, socket) do
    {:noreply, assign(socket, :chat_loading, loading)}
  end

  defp group_by_pillar(plan_modules) do
    plan_modules
    |> Enum.group_by(& &1.power_pillar)
    |> Enum.sort_by(fn {pillar, _} -> pillar_order(pillar) end)
  end

  defp pillar_order(:power_up), do: 0
  defp pillar_order(:power_through), do: 1
  defp pillar_order(:power_down), do: 2
  defp pillar_order(:empower), do: 3
  defp pillar_order(_), do: 4

  defp format_pillar(:power_up), do: gettext("Power Up")
  defp format_pillar(:power_through), do: gettext("Power Through")
  defp format_pillar(:power_down), do: gettext("Power Down")
  defp format_pillar(:empower), do: gettext("Empower")
  defp format_pillar(other), do: other |> to_string() |> String.capitalize()

  defp pillar_description(:power_up), do: gettext("Fuel your body and mind")
  defp pillar_description(:power_through), do: gettext("Build strength and endurance")
  defp pillar_description(:power_down), do: gettext("Rest, recover, and reset")
  defp pillar_description(:empower), do: gettext("Lead, influence, and grow")
  defp pillar_description(_), do: ""

  defp today_name do
    Date.utc_today()
    |> Date.day_of_week()
    |> day_number_to_name()
  end

  defp day_number_to_name(1), do: "monday"
  defp day_number_to_name(2), do: "tuesday"
  defp day_number_to_name(3), do: "wednesday"
  defp day_number_to_name(4), do: "thursday"
  defp day_number_to_name(5), do: "friday"
  defp day_number_to_name(6), do: "saturday"
  defp day_number_to_name(7), do: "sunday"

  defp format_day_name(day) do
    day |> String.capitalize()
  end

  @day_order ~w(monday tuesday wednesday thursday friday saturday sunday)

  defp sorted_schedule(schedule) when is_map(schedule) do
    @day_order
    |> Enum.map(fn day -> {day, Map.get(schedule, day, [])} end)
  end

  defp sorted_schedule(_), do: []
end
