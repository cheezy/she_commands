defmodule SheCommandsWeb.Admin.GoalCategoryLive.Index do
  use SheCommandsWeb, :live_view

  alias SheCommands.Intake
  alias SheCommands.Intake.GoalCategory

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Goal Categories"))
     |> assign_categories()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:editing_category, Intake.get_goal_category!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:editing_category, nil)
  end

  @impl true
  def handle_event("toggle", %{"id" => id}, socket) do
    {:ok, _updated} =
      id
      |> Intake.get_goal_category!()
      |> Intake.toggle_goal_category_visibility()

    {:noreply, assign_categories(socket)}
  end

  @impl true
  def handle_info({:saved, _category}, socket) do
    {:noreply,
     socket
     |> assign_categories()
     |> push_patch(to: ~p"/admin/goal-categories")}
  end

  defp assign_categories(socket) do
    assign(socket, :categories, Intake.list_goal_categories())
  end

  @doc """
  Public helper for templates: returns a fresh GoalCategory struct for
  the new-category form when needed in the future.
  """
  def blank_category, do: %GoalCategory{visible_on_intake: true}
end
