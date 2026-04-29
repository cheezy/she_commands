defmodule SheCommandsWeb.IntakeLive.Index do
  use SheCommandsWeb, :live_view

  alias SheCommands.Intake
  alias SheCommands.Plans

  @total_steps 8

  @step_required_fields %{
    1 => [:goal_intent],
    2 => [:goal_category_id],
    3 => [:lead_time],
    4 => [:days_per_week, :hours_per_day, :intensity]
  }

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
     |> assign(:goal_affirmation, Enum.random(goal_affirmations()))
     |> assign(:page_title, gettext("Your Personal Plan"))}
  end

  defp goal_affirmations do
    [
      gettext("That's a meaningful goal — here's how we'll approach it."),
      gettext("Beautiful clarity. Let's design a plan that honours it."),
      gettext("That intention matters. We'll build the path that gets you there."),
      gettext("A goal worth pursuing — let's set the foundation."),
      gettext("You're choosing growth. We'll meet you with a plan that fits."),
      gettext("That's the kind of goal that changes a life — let's start."),
      gettext("Powerful direction. Now let's translate it into protocols."),
      gettext("You've named what matters. The plan will reflect that."),
      gettext("That goal deserves a thoughtful approach — here's ours."),
      gettext("Clear intent, clear next step. Let's get to work.")
    ]
  end

  @impl true
  def handle_event("next", params, socket) do
    socket = save_step(socket, params)

    case validate_step(socket.assigns.response, socket.assigns.current_step) do
      :ok ->
        advance_step(socket)

      {:error, missing} ->
        {:noreply, put_flash(socket, :error, missing_fields_message(missing))}
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
    finalize_intake(socket)
  end

  @impl true
  def handle_event("select_category", %{"id" => id}, socket) do
    {:ok, response} =
      Intake.update_intake_goal(socket.assigns.response, %{goal_category_id: id})

    {:noreply, assign(socket, :response, response)}
  end

  @impl true
  def handle_event("select_option", %{"field" => field, "option" => value}, socket) do
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
  def handle_event("toggle_limitation", %{"option" => value}, socket) do
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

  defp finalize_intake(socket) do
    with :ok <- validate_step(socket.assigns.response, socket.assigns.current_step),
         {:ok, response} <- Intake.complete_intake_response(socket.assigns.response) do
      socket =
        socket
        |> assign(:response, response)
        |> assign(:current_step, @total_steps + 1)

      {:noreply, try_generate_plan(socket, response)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_flash(socket, :error, missing_fields_message(required_errors(changeset)))}

      {:error, missing_fields} when is_list(missing_fields) ->
        {:noreply, put_flash(socket, :error, missing_fields_message(missing_fields))}
    end
  end

  defp required_errors(%Ecto.Changeset{errors: errors}) do
    errors
    |> Enum.filter(fn {_field, {_msg, opts}} -> opts[:validation] == :required end)
    |> Enum.map(fn {field, _} -> field end)
  end

  defp advance_step(socket) do
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

  defp validate_step(_response, step) when step not in 1..4, do: :ok

  defp validate_step(response, step) do
    required = Map.fetch!(@step_required_fields, step)

    missing =
      Enum.filter(required, fn field ->
        value = Map.get(response, field)
        is_nil(value) or (is_binary(value) and String.trim(value) == "")
      end)

    case missing do
      [] -> :ok
      fields -> {:error, fields}
    end
  end

  defp missing_fields_message(fields) do
    formatted = Enum.map_join(fields, ", ", &format_required_field/1)

    gettext("Please complete the following before continuing: %{fields}", fields: formatted)
  end

  defp format_required_field(:goal_intent), do: gettext("Goal")
  defp format_required_field(:goal_category_id), do: gettext("Focus area")
  defp format_required_field(:lead_time), do: gettext("Timeline")
  defp format_required_field(:days_per_week), do: gettext("Days per week")
  defp format_required_field(:hours_per_day), do: gettext("Time per session")
  defp format_required_field(:intensity), do: gettext("Intensity")
  defp format_required_field(field), do: field |> to_string() |> String.replace("_", " ")

  defp save_step(socket, params) do
    case socket.assigns.current_step do
      1 -> save_goal_step(socket, params)
      4 -> save_availability_step(socket)
      5 -> save_limitations_step(socket, params)
      7 -> save_regimen_step(socket, params)
      8 -> save_location_step(socket, params)
      _ -> socket
    end
  end

  defp save_availability_step(socket) do
    response = socket.assigns.response

    if is_nil(response.days_per_week) do
      {:ok, response} =
        Intake.update_intake_availability(response, %{days_per_week: 3})

      assign(socket, :response, response)
    else
      socket
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

  defp try_generate_plan(socket, response) do
    case Plans.generate_plan(response) do
      {:ok, _plan} ->
        put_flash(socket, :info, gettext("Your plan has been generated!"))

      {:error, _reason} ->
        put_flash(
          socket,
          :info,
          gettext("Your intake is complete! Your plan is being assembled by our expert team.")
        )
    end
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
      phx-value-option={@value}
      class={"w-full text-left py-4 px-5 border transition-all duration-200 cursor-pointer #{if @selected, do: "border-base-content bg-base-content/5", else: "border-base-content/10 hover:border-base-content/30"}"}
    >
      <p class="text-sm font-semibold text-base-content">{@label}</p>
      <%= if @sublabel do %>
        <p class="text-xs text-base-content/60 mt-1">{@sublabel}</p>
      <% end %>
    </button>
    """
  end
end
