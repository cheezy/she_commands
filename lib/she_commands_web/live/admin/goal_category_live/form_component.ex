defmodule SheCommandsWeb.Admin.GoalCategoryLive.FormComponent do
  @moduledoc """
  Modal form for creating or updating a `SheCommands.Intake.GoalCategory`.

  Branches on whether `assigns.category.id` is set: when nil the
  changeset is a fresh insert (`Intake.create_goal_category/1`),
  otherwise it goes through `Intake.update_goal_category/2`. On success
  it sends `{:saved, category}` to the parent LiveView, which is
  responsible for refreshing its list and patching back to the index.
  """

  use SheCommandsWeb, :live_component

  alias SheCommands.Intake
  alias SheCommands.Intake.GoalCategory

  @impl true
  def update(%{category: category} = assigns, socket) do
    changeset = GoalCategory.changeset(category, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign_new(:return_to, fn -> "/admin/goal-categories" end)}
  end

  @impl true
  def handle_event("validate", %{"goal_category" => params}, socket) do
    changeset =
      socket.assigns.category
      |> GoalCategory.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"goal_category" => params}, socket) do
    save(socket, socket.assigns.category, params)
  end

  defp save(socket, %GoalCategory{id: nil}, params) do
    case Intake.create_goal_category(params) do
      {:ok, category} ->
        notify_parent({:saved, category})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save(socket, %GoalCategory{} = existing, params) do
    case Intake.update_goal_category(existing, params) do
      {:ok, category} ->
        notify_parent({:saved, category})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp notify_parent(message), do: send(self(), message)

  @doc """
  True when the category in the changeset is a new (unsaved) row.
  """
  def new?(changeset), do: is_nil(Ecto.Changeset.get_field(changeset, :id))

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class="fixed inset-0 z-50 flex items-center justify-center bg-base-200/90 p-4"
    >
      <div class="w-full max-w-2xl bg-base-100 border border-base-300 max-h-[90vh] overflow-y-auto">
        <div class="px-6 py-4 border-b border-base-300 flex items-center justify-between">
          <h2 class="text-2xl font-serif italic text-base-content">
            <%= if new?(@changeset) do %>
              {gettext("New goal category")}
            <% else %>
              {gettext("Edit goal category")}
            <% end %>
          </h2>
          <.link
            patch={@return_to}
            class="text-base-content/40 hover:text-base-content transition cursor-pointer"
            aria-label={gettext("Close")}
          >
            <.icon name="hero-x-mark" class="size-5" />
          </.link>
        </div>

        <.form
          :let={f}
          for={@changeset}
          as={:goal_category}
          id={"#{@id}-form"}
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
          class="p-6 space-y-4"
        >
          <.input field={f[:name]} type="text" label={gettext("Name")} required />
          <.input field={f[:slug]} type="text" label={gettext("Slug")} required />
          <.input field={f[:description]} type="textarea" label={gettext("Description")} rows="2" />
          <.input field={f[:position]} type="number" label={gettext("Position")} />

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <.input
              field={f[:outcome_power_up]}
              type="textarea"
              label={gettext("Power Up outcomes")}
              rows="3"
            />
            <.input
              field={f[:outcome_power_through]}
              type="textarea"
              label={gettext("Power Through outcomes")}
              rows="3"
            />
            <.input
              field={f[:outcome_power_down]}
              type="textarea"
              label={gettext("Power Down outcomes")}
              rows="3"
            />
            <.input
              field={f[:outcome_empower]}
              type="textarea"
              label={gettext("Empower outcomes")}
              rows="3"
            />
          </div>

          <.input
            field={f[:visible_on_intake]}
            type="checkbox"
            label={gettext("Visible on intake")}
          />

          <div class="flex justify-end gap-3 pt-4 border-t border-base-300">
            <.link
              patch={@return_to}
              class="py-3 px-6 text-xs font-label uppercase tracking-[0.2em] text-base-content/60 hover:text-base-content transition"
            >
              {gettext("Cancel")}
            </.link>
            <button
              type="submit"
              class="py-3 px-8 bg-base-content text-base-100 text-xs font-label uppercase tracking-[0.2em] hover:bg-base-content/90 transition cursor-pointer"
            >
              {gettext("Save")}
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
