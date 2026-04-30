defmodule SheCommandsWeb.Admin.GoalCategoryLive.Index do
  use SheCommandsWeb, :live_view

  alias SheCommands.Intake

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Goal Categories"))
     |> assign_categories()}
  end

  @impl true
  def handle_event("toggle", %{"id" => id}, socket) do
    category = Intake.get_goal_category!(id)

    case Intake.toggle_goal_category_visibility(category) do
      {:ok, _updated} ->
        {:noreply, assign_categories(socket)}

      {:error, _changeset} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext("Could not update visibility for %{name}", name: category.name)
         )}
    end
  end

  defp assign_categories(socket) do
    assign(socket, :categories, Intake.list_goal_categories())
  end
end
