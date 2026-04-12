defmodule SheCommands.Plans.ScheduleBuilder do
  @moduledoc """
  Generates a day-by-day weekly schedule from selected plan modules.

  Distributes protocols across available days with balanced Power Pillar
  coverage per day, respecting the user's time constraints.
  """

  @day_names ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

  @doc """
  Builds a weekly schedule from plan modules and intake constraints.

  Returns a map of day_name => list of protocol assignments.

  ## Examples

      build_schedule(plan_modules, 5, :thirty_to_sixty)
      #=> %{
      #=>   "monday" => [%{module_id: 1, title: "...", pillar: :power_up, time: 15}],
      #=>   "tuesday" => [...],
      #=>   ...
      #=> }
  """
  def build_schedule(plan_modules, days_per_week, hours_per_day) do
    max_daily_minutes = map_hours_per_day(hours_per_day)
    active_days = Enum.take(@day_names, days_per_week)

    # Build protocol entries from plan modules
    entries = build_entries(plan_modules)

    # Distribute entries across days
    schedule = distribute_entries(entries, active_days, max_daily_minutes)

    # Mark rest days
    rest_days =
      @day_names
      |> Enum.drop(days_per_week)
      |> Enum.map(fn day -> {day, []} end)
      |> Map.new()

    Map.merge(schedule, rest_days)
  end

  defp map_hours_per_day(:under_30), do: 30
  defp map_hours_per_day(:thirty_to_sixty), do: 60
  defp map_hours_per_day(:over_sixty), do: 90
  defp map_hours_per_day(_), do: 60

  defp build_entries(plan_modules) do
    Enum.map(plan_modules, fn pm ->
      module = pm.module

      %{
        module_id: module.id,
        module_title: module.title,
        power_pillar: pm.power_pillar,
        daily_time: module.daily_time || 15,
        weekly_freq: module.weekly_freq || 3
      }
    end)
  end

  defp distribute_entries(entries, active_days, max_daily_minutes) do
    initial_state = init_schedule_state(active_days)
    sorted_entries = Enum.sort_by(entries, & &1.power_pillar)

    {schedule, _times} =
      Enum.reduce(sorted_entries, initial_state, fn entry, state ->
        assign_entry_to_day(entry, active_days, max_daily_minutes, state)
      end)

    schedule
  end

  defp init_schedule_state(active_days) do
    schedule = Map.new(active_days, fn day -> {day, []} end)
    times = Map.new(active_days, fn day -> {day, 0} end)
    {schedule, times}
  end

  defp assign_entry_to_day(entry, active_days, max_daily_minutes, {sched, times}) do
    day = find_best_day(active_days, times, entry.daily_time, max_daily_minutes)
    assignment = build_assignment(entry)

    updated_sched = Map.update!(sched, day, fn days -> days ++ [assignment] end)
    updated_times = Map.update!(times, day, fn t -> t + entry.daily_time end)
    {updated_sched, updated_times}
  end

  defp find_best_day(active_days, times, entry_time, max_minutes) do
    # Prefer day that can fit within constraints
    fitting_day =
      active_days
      |> Enum.filter(fn day -> Map.get(times, day, 0) + entry_time <= max_minutes end)
      |> Enum.min_by(fn day -> Map.get(times, day, 0) end, fn -> nil end)

    # Fall back to least-loaded day (best effort)
    fitting_day || Enum.min_by(active_days, fn day -> Map.get(times, day, 0) end)
  end

  defp build_assignment(entry) do
    %{
      module_id: entry.module_id,
      module_title: entry.module_title,
      power_pillar: entry.power_pillar,
      daily_time: entry.daily_time
    }
  end
end
