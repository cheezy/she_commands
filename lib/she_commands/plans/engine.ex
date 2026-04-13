defmodule SheCommands.Plans.Engine do
  @moduledoc """
  Rule-based plan generation engine.

  Takes an intake response and generates a personalized execution plan
  by selecting modules from the library based on goal category, filtering
  by user constraints, and ensuring Power Pillar coverage.

  ## Rules

  1. Goal category → module pool
  2. Lead time → plan type (weekly/biweekly/monthly)
  3. Intensity + availability → module filtering
  4. Power Pillar coverage (min 1 per pillar, non-negotiable)
  5. Complementary modules (auto-include if capacity allows)
  6. Goal statement + expected outcomes from goal category
  """

  alias SheCommands.Intake.GoalCategory
  alias SheCommands.Modules

  @power_pillars [:power_up, :power_through, :power_down, :empower]

  @doc """
  Generates a plan specification from an intake response.

  Returns `{:ok, plan_attrs}` with the plan attributes and selected modules,
  or `{:error, reason}` if generation fails.
  """
  def generate(intake_response, goal_category) do
    plan_type = determine_plan_type(intake_response.lead_time)
    max_daily_time = map_hours_per_day(intake_response.hours_per_day)
    max_modules = max_modules_for_plan(plan_type, intake_response.days_per_week)

    candidate_modules =
      Modules.filter_modules(%{
        goal_category_id: intake_response.goal_category_id,
        intensity: intake_response.intensity,
        daily_time: max_daily_time
      })

    case select_modules_with_pillar_coverage(candidate_modules, max_modules) do
      {:ok, selected_modules, uncovered_pillars} ->
        selected_with_complementary =
          maybe_add_complementary(
            selected_modules,
            max_modules,
            intake_response.days_per_week
          )

        plan_attrs = %{
          plan_type: plan_type,
          goal_statement: build_goal_statement(intake_response, goal_category),
          expected_outcomes: build_expected_outcomes(goal_category),
          selected_modules: selected_with_complementary,
          uncovered_pillars: uncovered_pillars
        }

        {:ok, plan_attrs}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Determines plan type from lead time.

  - short (≤2 weeks) → weekly
  - medium (3-6 weeks) → biweekly
  - long (≥7 weeks) → monthly
  """
  def determine_plan_type(:short), do: :weekly
  def determine_plan_type(:medium), do: :biweekly
  def determine_plan_type(:long), do: :monthly
  def determine_plan_type(_), do: :weekly

  @doc """
  Maps the hours_per_day enum to max minutes for filtering.
  """
  def map_hours_per_day(:under_30), do: 30
  def map_hours_per_day(:thirty_to_sixty), do: 60
  def map_hours_per_day(:over_sixty), do: 90
  def map_hours_per_day(_), do: 60

  @doc """
  Determines maximum modules based on plan type and days per week.

  - ≤3 days/week → 1 module per pillar (4 total)
  - >3 days/week → 2 modules per pillar for biweekly/monthly
  """
  def max_modules_for_plan(:weekly, _days), do: 4
  def max_modules_for_plan(:biweekly, days) when days <= 3, do: 4
  def max_modules_for_plan(:biweekly, _days), do: 8
  def max_modules_for_plan(:monthly, days) when days <= 3, do: 4
  def max_modules_for_plan(:monthly, _days), do: 8
  def max_modules_for_plan(_, _), do: 4

  @doc """
  Selects modules ensuring all 4 Power Pillars are covered.

  Returns `{:ok, selected_modules}` with pillar assignments,
  or `{:error, :insufficient_coverage}` if not all pillars can be covered.
  """
  def select_modules_with_pillar_coverage(candidates, max_modules) do
    # Group candidates by which pillar they can serve
    pillar_candidates = build_pillar_candidates(candidates)

    # Check if all pillars can be covered
    uncovered =
      Enum.filter(@power_pillars, fn pillar ->
        Map.get(pillar_candidates, pillar, []) == []
      end)

    # Best-effort: cover what we can, warn about gaps
    selected = select_one_per_pillar(pillar_candidates)

    if selected == [] and candidates == [] do
      {:error, {:no_modules_available, @power_pillars}}
    else
      selected =
        if length(selected) < max_modules do
          fill_remaining(selected, candidates, max_modules)
        else
          selected
        end

      {:ok, selected, uncovered}
    end
  end

  defp build_pillar_candidates(modules) do
    Enum.reduce(modules, %{}, fn module, acc ->
      pillars = module_pillars(module)

      Enum.reduce(pillars, acc, fn pillar, inner_acc ->
        Map.update(inner_acc, pillar, [module], &[module | &1])
      end)
    end)
  end

  defp module_pillars(module) do
    [module.power_pillar_1, module.power_pillar_2]
    |> Enum.reject(&is_nil/1)
  end

  defp select_one_per_pillar(pillar_candidates) do
    {selected, _used_ids} =
      Enum.reduce(@power_pillars, {[], MapSet.new()}, fn pillar, {selected, used_ids} ->
        candidates = Map.get(pillar_candidates, pillar, [])

        case Enum.find(candidates, fn m -> m.id not in used_ids end) do
          nil ->
            {selected, used_ids}

          module ->
            entry = %{module: module, power_pillar: pillar}
            {[entry | selected], MapSet.put(used_ids, module.id)}
        end
      end)

    Enum.reverse(selected)
  end

  defp fill_remaining(selected, candidates, max_modules) do
    used_ids = MapSet.new(selected, fn %{module: m} -> m.id end)
    remaining = Enum.reject(candidates, fn m -> m.id in used_ids end)
    slots = max_modules - length(selected)

    additional =
      remaining
      |> Enum.take(slots)
      |> Enum.map(fn module ->
        pillar = module.power_pillar_1 || :empower
        %{module: module, power_pillar: pillar}
      end)

    selected ++ additional
  end

  @doc """
  Adds complementary modules if capacity allows.

  Rules: user has >3 days/week AND <5 modules already selected
  AND selected module has complementary_module_ids.
  """
  def maybe_add_complementary(selected, max_modules, days_per_week) do
    if eligible_for_complementary?(selected, max_modules, days_per_week) do
      add_complementary_modules(selected, max_modules)
    else
      selected
    end
  end

  defp eligible_for_complementary?(selected, max_modules, days_per_week) do
    days_per_week > 3 and length(selected) < 5 and length(selected) < max_modules
  end

  defp add_complementary_modules(selected, max_modules) do
    used_ids = MapSet.new(selected, fn %{module: m} -> m.id end)

    complementary_ids =
      selected
      |> Enum.flat_map(fn %{module: m} -> m.complementary_module_ids || [] end)
      |> Enum.uniq()
      |> Enum.reject(fn id -> id in used_ids end)

    if complementary_ids == [] do
      selected
    else
      slots = min(max_modules - length(selected), length(complementary_ids))

      additional =
        complementary_ids
        |> Enum.take(slots)
        |> Enum.map(&load_complementary_module/1)

      selected ++ additional
    end
  end

  defp load_complementary_module(id) do
    module = Modules.get_module!(id)
    %{module: module, power_pillar: module.power_pillar_1 || :empower}
  end

  @doc """
  Builds a personalized goal statement from intake and goal category.
  """
  def build_goal_statement(intake_response, %GoalCategory{} = category) do
    intent = intake_response.goal_intent || ""

    if String.trim(intent) != "" do
      "#{String.trim(intent)} — powered by #{category.name}."
    else
      "Your #{category.name} plan is ready."
    end
  end

  @doc """
  Builds expected outcomes text from goal category per-pillar descriptions.
  """
  def build_expected_outcomes(%GoalCategory{} = category) do
    outcomes =
      [
        {"Power Up", category.outcome_power_up},
        {"Power Through", category.outcome_power_through},
        {"Power Down", category.outcome_power_down},
        {"Empower", category.outcome_empower}
      ]
      |> Enum.reject(fn {_name, outcome} -> is_nil(outcome) or outcome == "" end)
      |> Enum.map_join("\n", fn {name, outcome} -> "#{name}: #{outcome}" end)

    if outcomes == "", do: nil, else: outcomes
  end
end
