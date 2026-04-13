defmodule SheCommandsWeb.PlanLive.Show do
  use SheCommandsWeb, :live_view

  alias SheCommands.Chat
  alias SheCommands.Chat.ClaudeClient
  alias SheCommands.Chat.ContextBuilder
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
       |> assign(:chat_loading, false)
       |> assign(:chat_error, false)}
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

  def handle_event("send_message", _params, %{assigns: %{chat_loading: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("send_message", %{"message" => content}, socket)
      when content != "" do
    trimmed = String.trim(content)

    if trimmed != "" do
      create_and_send_message(socket, trimmed)
    else
      {:noreply, socket}
    end
  end

  def handle_event("send_message", _params, socket), do: {:noreply, socket}

  def handle_event("suggest_question", %{"question" => question}, socket) do
    handle_event("send_message", %{"message" => question}, socket)
  end

  def handle_event("retry_message", _params, socket) do
    send_to_ai(socket)
  end

  def handle_event("clear_chat", _params, socket) do
    Chat.clear_conversation(
      socket.assigns.plan.id,
      socket.assigns.current_scope.user.id
    )

    {:noreply,
     socket
     |> assign(:chat_messages, [])
     |> assign(:chat_loading, false)
     |> assign(:chat_error, false)}
  end

  @impl true
  def handle_info({ref, {:ok, content}}, socket) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    case Chat.create_message(%{
           user_id: socket.assigns.current_scope.user.id,
           plan_id: socket.assigns.plan.id,
           role: :assistant,
           content: content
         }) do
      {:ok, assistant_msg} ->
        {:noreply,
         socket
         |> assign(:chat_messages, socket.assigns.chat_messages ++ [assistant_msg])
         |> assign(:chat_loading, false)
         |> assign(:chat_error, false)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(:chat_loading, false)
         |> assign(:chat_error, true)}
    end
  end

  def handle_info({ref, {:error, _reason}}, socket) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    {:noreply,
     socket
     |> assign(:chat_loading, false)
     |> assign(:chat_error, true)}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply,
     socket
     |> assign(:chat_loading, false)
     |> assign(:chat_error, true)}
  end

  def handle_info({:set_chat_loading, loading}, socket) do
    {:noreply, assign(socket, :chat_loading, loading)}
  end

  defp create_and_send_message(socket, content) do
    user = socket.assigns.current_scope.user
    plan = socket.assigns.plan

    case Chat.create_message(%{
           user_id: user.id,
           plan_id: plan.id,
           role: :user,
           content: content
         }) do
      {:ok, user_msg} ->
        socket
        |> assign(:chat_messages, socket.assigns.chat_messages ++ [user_msg])
        |> send_to_ai()

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to send message."))}
    end
  end

  defp send_to_ai(socket) do
    plan = socket.assigns.plan
    messages = socket.assigns.chat_messages
    system_prompt = ContextBuilder.build_system_prompt(plan)

    Task.Supervisor.async_nolink(SheCommands.TaskSupervisor, fn ->
      ClaudeClient.send_message(messages, system: system_prompt)
    end)

    {:noreply,
     socket
     |> assign(:chat_loading, true)
     |> assign(:chat_error, false)}
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
