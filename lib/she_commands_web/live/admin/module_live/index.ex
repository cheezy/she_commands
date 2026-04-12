defmodule SheCommandsWeb.Admin.ModuleLive.Index do
  use SheCommandsWeb, :live_view

  alias SheCommands.Intake
  alias SheCommands.Modules

  @impl true
  def mount(_params, _session, socket) do
    goal_categories = Intake.list_goal_categories()
    contributors = Modules.list_contributors()

    {:ok,
     socket
     |> assign(:page_title, gettext("Module Library"))
     |> assign(:goal_categories, goal_categories)
     |> assign(:contributors, contributors)
     |> assign(:filters, %{})
     |> assign_modules(%{})}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters =
      %{}
      |> maybe_put(:power_pillar, params["power_pillar"])
      |> maybe_put(:goal_category_id, params["goal_category_id"])
      |> maybe_put(:contributor, params["contributor"])
      |> maybe_put(:module_type, params["module_type"])

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_modules(filters)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, %{})
     |> assign_modules(%{})}
  end

  defp assign_modules(socket, filters) do
    modules =
      filters
      |> convert_filter_types()
      |> Modules.filter_modules()

    modules_with_completeness =
      Enum.map(modules, fn module ->
        {pct, missing} = Modules.module_completeness(module)
        %{module: module, completeness: pct, missing_fields: missing}
      end)

    assign(socket, :modules, modules_with_completeness)
  end

  defp convert_filter_types(filters) do
    filters
    |> maybe_convert(:power_pillar, &String.to_existing_atom/1)
    |> maybe_convert(:goal_category_id, &String.to_integer/1)
    |> maybe_convert(:module_type, &String.to_existing_atom/1)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_convert(map, key, converter) do
    case Map.get(map, key) do
      nil -> map
      value -> Map.put(map, key, converter.(value))
    end
  end

  defp format_power_pillar(pillar) do
    pillar
    |> to_string()
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp completeness_color(pct) when pct >= 80, do: "text-success"
  defp completeness_color(pct) when pct >= 50, do: "text-warning"
  defp completeness_color(_pct), do: "text-error"
end
