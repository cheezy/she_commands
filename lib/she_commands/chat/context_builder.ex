defmodule SheCommands.Chat.ContextBuilder do
  @moduledoc """
  Builds RAG context from a preloaded Plan for the AI chat assistant.

  Transforms plan data — goal statement, modules, protocols, and goal
  categories — into structured text suitable for use as system prompt
  context. Performs pure data transformation with no database access.
  """

  alias SheCommands.Plans.Plan

  @doc """
  Builds a structured text context from a preloaded plan.

  Accepts a `%Plan{}` with preloaded associations (`plan_modules`,
  modules with `protocols` and `goal_categories`) and returns a
  markdown-formatted string containing the plan's goal, outcomes,
  schedule, goal categories, and module/protocol details.
  """
  def build_context(%Plan{} = plan) do
    [
      build_goal_section(plan),
      build_schedule_section(plan),
      build_goal_categories_section(plan),
      build_modules_section(plan)
    ]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n\n")
  end

  @doc """
  Builds the full system prompt for the AI chat assistant.

  Wraps the plan context from `build_context/1` with brand voice
  instructions and safety guardrails.
  """
  def build_system_prompt(%Plan{} = plan) do
    context = build_context(plan)

    """
    ## Role
    You are a supportive coaching assistant for SheCommands. You help users \
    understand and follow their personalized plan.

    ## Voice
    - Be direct, warm, and encouraging
    - Avoid clinical or academic language
    - Speak like a trusted coach, not a textbook

    ## Plan Context
    #{context}

    ## Boundaries
    - Do NOT provide medical advice or diagnoses
    - Do NOT provide nutritional advice or meal plans
    - Do NOT provide fitness programming or exercise prescriptions
    - If asked about these topics, kindly redirect the user to a qualified professional
    - Stay focused on the user's plan content and coaching guidance\
    """
  end

  defp build_goal_section(plan) do
    lines =
      [
        maybe_line("## Your Goal", plan.goal_statement),
        maybe_line("## Expected Outcomes", plan.expected_outcomes)
      ]
      |> Enum.reject(&is_nil/1)

    Enum.join(lines, "\n\n")
  end

  defp build_schedule_section(%{schedule: schedule})
       when is_nil(schedule) or schedule == %{} do
    ""
  end

  defp build_schedule_section(%{schedule: schedule}) do
    days =
      schedule
      |> Enum.sort_by(fn {day, _} -> day_order(day) end)
      |> Enum.map(fn {day, activities} ->
        count = length(activities)
        "- #{String.capitalize(day)}: #{count} #{pluralize(count, "activity", "activities")}"
      end)

    "## Weekly Schedule\n#{Enum.join(days, "\n")}"
  end

  defp build_goal_categories_section(plan) do
    categories =
      plan.plan_modules
      |> Enum.flat_map(fn pm -> pm.module.goal_categories end)
      |> Enum.uniq_by(& &1.id)

    case categories do
      [] ->
        ""

      cats ->
        lines = Enum.map(cats, &format_goal_category/1)
        "## Goal Categories\n#{Enum.join(lines, "\n")}"
    end
  end

  defp build_modules_section(%{plan_modules: []}) do
    ""
  end

  defp build_modules_section(plan) do
    modules =
      plan.plan_modules
      |> Enum.sort_by(& &1.position)
      |> Enum.with_index(1)
      |> Enum.map(fn {pm, index} -> format_module(pm, index) end)

    "## Modules\n\n#{Enum.join(modules, "\n\n")}"
  end

  defp format_module(plan_module, index) do
    mod = plan_module.module
    pillar = humanize(plan_module.power_pillar)

    header = "### Module #{index}: #{mod.title} (#{pillar})"

    fields =
      [
        maybe_line("Overview", mod.overview),
        maybe_line("Core Concepts", mod.core_concepts),
        maybe_line("Outcomes", mod.outcomes),
        maybe_line("Coach Tip", mod.coach_tip)
      ]
      |> Enum.reject(&is_nil/1)

    protocols = format_protocols(mod.protocols)

    [header | fields]
    |> Enum.join("\n")
    |> then(fn text ->
      if protocols == "", do: text, else: text <> "\n" <> protocols
    end)
  end

  defp format_protocols(protocols) do
    protocols
    |> Enum.sort_by(& &1.position)
    |> Enum.map_join("\n", &format_protocol/1)
  end

  defp format_protocol(protocol) do
    lines =
      [
        "#### Protocol #{protocol.position}: #{protocol.purpose || "Untitled"}",
        maybe_line("Steps", protocol.steps),
        maybe_line("Prescription", protocol.prescription),
        maybe_line("Expected Outcome", protocol.expected_outcome)
      ]
      |> Enum.reject(&is_nil/1)

    Enum.join(lines, "\n")
  end

  defp format_goal_category(category) do
    case category.description do
      nil -> "- #{category.name}"
      desc -> "- #{category.name}: #{desc}"
    end
  end

  defp maybe_line(_label, nil), do: nil
  defp maybe_line(_label, ""), do: nil

  defp maybe_line(label, value) do
    if String.starts_with?(label, "##") do
      "#{label}\n#{value}"
    else
      "#{label}: #{value}"
    end
  end

  defp humanize(atom) when is_atom(atom) do
    atom
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  @day_order %{
    "monday" => 0,
    "tuesday" => 1,
    "wednesday" => 2,
    "thursday" => 3,
    "friday" => 4,
    "saturday" => 5,
    "sunday" => 6
  }

  defp day_order(day), do: Map.get(@day_order, String.downcase(day), 7)

  defp pluralize(1, singular, _plural), do: singular
  defp pluralize(_count, _singular, plural), do: plural
end
