defmodule Mix.Tasks.ImportModules do
  @moduledoc """
  Imports or updates the module library from the JSON data file.

  The JSON file is generated from the master spreadsheet using a Python script.

  ## Usage

      mix import_modules

  This task is idempotent — existing modules are updated by title match,
  new modules are created. Protocols are replaced on update.
  """

  use Mix.Task

  import Ecto.Query

  alias SheCommands.Intake.GoalCategory
  alias SheCommands.Modules
  alias SheCommands.Modules.Module
  alias SheCommands.Modules.Protocol
  alias SheCommands.Repo

  @data_path "priv/repo/seeds/module_data.json"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    data = @data_path |> File.read!() |> Jason.decode!()

    categories = load_category_map()

    IO.puts("\n=== Importing #{length(data)} Modules ===\n")

    {created, updated} =
      Enum.reduce(data, {0, 0}, fn module_data, {c, u} ->
        case import_module(module_data, categories) do
          :created -> {c + 1, u}
          :updated -> {c, u + 1}
        end
      end)

    total = Repo.aggregate(Module, :count)
    proto_count = Repo.aggregate(Protocol, :count)

    IO.puts("\n=== Import Complete ===")
    IO.puts("Created: #{created}, Updated: #{updated}")
    IO.puts("Total modules: #{total}, Total protocols: #{proto_count}")
  end

  defp load_category_map do
    GoalCategory
    |> Repo.all()
    |> Enum.map(fn cat -> {cat.name, cat} end)
    |> Map.new()
  end

  defp import_module(data, categories) do
    attrs = build_attrs(data)
    goal_cats = resolve_categories(data["categories"] || [], categories)
    protocols = data["protocols"] || []

    case find_existing_module(data) do
      nil ->
        {:ok, module} = Modules.create_module_with_categories(attrs, goal_cats)
        create_protocols(module.id, protocols)
        IO.puts("  Created: #{data["title"]} (#{data["module_id"]})")
        :created

      existing ->
        {:ok, module} = Modules.update_module(existing, attrs)
        update_categories(module, goal_cats)
        replace_protocols(module.id, protocols)
        IO.puts("  Updated: #{data["title"]} (#{data["module_id"]})")
        :updated
    end
  end

  defp find_existing_module(data) do
    # Try by module_id first, then by exact title, then case-insensitive title
    Repo.get_by(Module, module_id: data["module_id"]) ||
      Repo.get_by(Module, title: data["title"]) ||
      find_by_title_insensitive(data["title"])
  end

  defp build_attrs(data) do
    %{
      module_id: data["module_id"],
      contributor: data["contributor"],
      title: data["title"],
      overview: non_empty(data["overview"]),
      core_concepts: non_empty(data["core_concepts"]),
      power_pillar_1: safe_atom(data["power_pillar_1"]),
      power_pillar_2: safe_atom(data["power_pillar_2"]),
      module_type: :foundational,
      intensity: safe_atom(data["intensity"] || "moderate"),
      daily_time: data["daily_time"],
      weekly_freq: data["weekly_freq"],
      lead_time_fit: :short,
      experience_level: non_empty(data["experience_level"]),
      outcomes: non_empty(data["outcomes"]),
      modifications: non_empty(data["modifications"]),
      coach_tip: non_empty(data["coach_tip"]),
      coach_tip_attribution: if(non_empty(data["coach_tip"]), do: data["contributor"]),
      time_to_result: non_empty(data["time_to_result"])
    }
  end

  defp resolve_categories(names, category_map) do
    names
    |> Enum.map(&Map.get(category_map, &1))
    |> Enum.reject(&is_nil/1)
  end

  defp update_categories(module, goal_cats) do
    module
    |> Repo.preload(:goal_categories)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:goal_categories, goal_cats)
    |> Repo.update!()
  end

  defp replace_protocols(module_id, protocols) do
    Protocol
    |> where([p], p.module_id == ^module_id)
    |> Repo.delete_all()

    create_protocols(module_id, protocols)
  end

  defp create_protocols(module_id, protocols) do
    for proto <- protocols do
      Modules.create_protocol(%{
        module_id: module_id,
        position: proto["position"],
        purpose: proto["purpose"] || "",
        steps: proto["steps"] || "",
        prescription: proto["prescription"] || "",
        expected_outcome: proto["expected_outcome"]
      })
    end
  end

  defp find_by_title_insensitive(title) do
    Module
    |> where([m], fragment("lower(?)", m.title) == ^String.downcase(title))
    |> limit(1)
    |> Repo.one()
  end

  defp non_empty(""), do: nil
  defp non_empty(nil), do: nil
  defp non_empty(val), do: val

  @valid_atoms ~w(power_up power_through power_down empower low moderate high
                   foundational secondary assisted bespoke short medium long)a
               |> Enum.map(fn a -> {Atom.to_string(a), a} end)
               |> Map.new()

  defp safe_atom(nil), do: nil
  defp safe_atom(""), do: nil
  defp safe_atom(val) when is_atom(val), do: val
  defp safe_atom(val), do: Map.get(@valid_atoms, val)
end
