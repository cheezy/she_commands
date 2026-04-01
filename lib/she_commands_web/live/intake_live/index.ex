defmodule SheCommandsWeb.IntakeLive.Index do
  use SheCommandsWeb, :live_view

  alias SheCommands.Intake

  @total_steps 8

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    {:ok, response} = Intake.get_or_create_active_intake_response(user)
    goal_categories = Intake.list_goal_categories()

    {:ok,
     socket
     |> assign(:response, response)
     |> assign(:current_step, response.current_step)
     |> assign(:total_steps, @total_steps)
     |> assign(:goal_categories, goal_categories)
     |> assign(:page_title, gettext("Your Personal Plan"))}
  end

  @impl true
  def handle_event("next", params, socket) do
    socket = save_step(socket, params)

    if socket.assigns.current_step < @total_steps do
      next_step = socket.assigns.current_step + 1

      {:ok, response} = Intake.update_intake_step(socket.assigns.response, next_step)

      {:noreply,
       socket
       |> assign(:response, response)
       |> assign(:current_step, next_step)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("back", _params, socket) do
    if socket.assigns.current_step > 1 do
      prev_step = socket.assigns.current_step - 1
      {:ok, response} = Intake.update_intake_step(socket.assigns.response, prev_step)

      {:noreply,
       socket
       |> assign(:response, response)
       |> assign(:current_step, prev_step)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("complete", params, socket) do
    socket = save_step(socket, params)

    case Intake.complete_intake_response(socket.assigns.response) do
      {:ok, response} ->
        {:noreply,
         socket
         |> assign(:response, response)
         |> assign(:current_step, @total_steps + 1)
         |> put_flash(:info, gettext("Your intake is complete! Your plan is being generated."))}

      {:error, _changeset} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext("Please complete all required fields before finishing.")
         )}
    end
  end

  @impl true
  def handle_event("select_category", %{"id" => id}, socket) do
    {:ok, response} =
      Intake.update_intake_goal(socket.assigns.response, %{goal_category_id: id})

    {:noreply, assign(socket, :response, response)}
  end

  @impl true
  def handle_event("select_option", %{"field" => field, "value" => value}, socket) do
    response = socket.assigns.response

    {:ok, response} =
      case field do
        "lead_time" ->
          Intake.update_intake_availability(response, %{lead_time: value})

        "hours_per_day" ->
          Intake.update_intake_availability(response, %{hours_per_day: value})

        "intensity" ->
          Intake.update_intake_availability(response, %{intensity: value})

        "coaching_preference" ->
          Intake.update_intake_preferences(response, %{coaching_preference: value})

        "fitness_regimen" ->
          Intake.update_intake_regimen(response, %{fitness_regimen: value})

        "personal_dev_regimen" ->
          Intake.update_intake_regimen(response, %{personal_dev_regimen: value})

        _ ->
          {:ok, response}
      end

    {:noreply, assign(socket, :response, response)}
  end

  @impl true
  def handle_event("toggle_limitation", %{"value" => value}, socket) do
    response = socket.assigns.response
    current = response.limitations || []

    updated =
      if value in current,
        do: List.delete(current, value),
        else: current ++ [value]

    {:ok, response} = Intake.update_intake_preferences(response, %{limitations: updated})
    {:noreply, assign(socket, :response, response)}
  end

  @impl true
  def handle_event("update_days", %{"days" => days}, socket) do
    case Integer.parse(days) do
      {n, _} when n >= 1 and n <= 7 ->
        {:ok, response} =
          Intake.update_intake_availability(socket.assigns.response, %{days_per_week: n})

        {:noreply, assign(socket, :response, response)}

      _ ->
        {:noreply, socket}
    end
  end

  defp save_step(socket, params) do
    case socket.assigns.current_step do
      1 -> save_goal_step(socket, params)
      5 -> save_limitations_step(socket, params)
      7 -> save_regimen_step(socket, params)
      8 -> save_location_step(socket, params)
      _ -> socket
    end
  end

  defp save_goal_step(socket, %{"goal_intent" => goal_intent}) do
    {:ok, response} =
      Intake.update_intake_goal(socket.assigns.response, %{goal_intent: goal_intent})

    assign(socket, :response, response)
  end

  defp save_goal_step(socket, _params), do: socket

  defp save_limitations_step(socket, params) do
    notes = params["limitations_notes"] || ""

    {:ok, response} =
      Intake.update_intake_preferences(socket.assigns.response, %{limitations_notes: notes})

    assign(socket, :response, response)
  end

  defp save_regimen_step(socket, params) do
    attrs = %{
      fitness_regimen_notes: params["fitness_regimen_notes"] || "",
      personal_dev_regimen_notes: params["personal_dev_regimen_notes"] || ""
    }

    {:ok, response} = Intake.update_intake_regimen(socket.assigns.response, attrs)
    assign(socket, :response, response)
  end

  defp save_location_step(socket, params) do
    attrs = %{
      city: params["city"] || "",
      province: params["province"] || "",
      country: params["country"] || "",
      feedback_interest: params["feedback_interest"] == "true"
    }

    {:ok, response} = Intake.update_intake_location(socket.assigns.response, attrs)
    assign(socket, :response, response)
  end

  defp progress_percentage(current_step, total_steps) do
    round(current_step / total_steps * 100)
  end

  defp option_selected?(response_value, option_value) do
    to_string(response_value) == to_string(option_value)
  end

  defp limitation_selected?(limitations, value) do
    value in (limitations || [])
  end

  defp format_limitation(limitation) do
    limitation
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  attr :label, :string, required: true
  attr :sublabel, :string, default: nil
  attr :selected, :boolean, default: false
  attr :click, :string, required: true
  attr :field, :string, default: nil
  attr :value, :string, default: nil

  defp option_button(assigns) do
    ~H"""
    <button
      phx-click={@click}
      phx-value-field={@field}
      phx-value-value={@value}
      class={"w-full text-left p-4 rounded-lg border transition-all duration-200 #{if @selected, do: "border-primary bg-primary/10", else: "border-base-300 bg-base-100 hover:border-primary/50"}"}
    >
      <p class="font-semibold text-base-content">{@label}</p>
      <%= if @sublabel do %>
        <p class="text-sm text-base-content opacity-70 mt-1">{@sublabel}</p>
      <% end %>
    </button>
    """
  end
end
