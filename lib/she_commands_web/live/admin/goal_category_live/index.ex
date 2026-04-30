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
    {:ok, _updated} =
      id
      |> Intake.get_goal_category!()
      |> Intake.toggle_goal_category_visibility()

    {:noreply, assign_categories(socket)}
  end

  defp assign_categories(socket) do
    assign(socket, :categories, Intake.list_goal_categories())
  end
end
