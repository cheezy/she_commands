defmodule SheCommandsWeb.Admin.ModuleLive.Show do
  use SheCommandsWeb, :live_view

  alias SheCommands.Modules

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    module = Modules.get_module!(id)
    {completeness, missing} = Modules.module_completeness(module)

    {:ok,
     socket
     |> assign(:page_title, module.title)
     |> assign(:module, module)
     |> assign(:completeness, completeness)
     |> assign(:missing_fields, missing)}
  end

  defp format_power_pillar(nil), do: nil

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

  defp format_field_name(field) do
    field
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
