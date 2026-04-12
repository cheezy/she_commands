defmodule SheCommands.Modules do
  @moduledoc """
  The Modules context.

  Provides query functions for the module library, the data engine
  that powers personalized plan generation. All queries use composable
  functions that can be chained for the logic engine's filtering needs.
  """

  import Ecto.Query, warn: false

  alias SheCommands.Modules.Module
  alias SheCommands.Modules.Protocol
  alias SheCommands.Repo

  ## Modules

  @doc """
  Returns a list of all modules, preloading protocols and goal categories.
  """
  def list_modules do
    Module
    |> order_by(:title)
    |> preload([:protocols, :goal_categories])
    |> Repo.all()
  end

  @doc """
  Gets a single module by ID, preloading protocols and goal categories.

  Raises `Ecto.NoResultsError` if the module does not exist.
  """
  def get_module!(id) do
    Module
    |> preload([:protocols, :goal_categories])
    |> Repo.get!(id)
  end

  @doc """
  Gets a single module by its module_id string.

  Returns `nil` if not found.
  """
  def get_module_by_module_id(module_id) do
    Module
    |> preload([:protocols, :goal_categories])
    |> Repo.get_by(module_id: module_id)
  end

  @doc """
  Creates a module.
  """
  def create_module(attrs \\ %{}) do
    %Module{}
    |> Module.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a module and associates it with goal categories.

  Accepts a list of `GoalCategory` structs in the `goal_categories` key.
  """
  def create_module_with_categories(attrs, goal_categories) do
    %Module{}
    |> Module.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:goal_categories, goal_categories)
    |> Repo.insert()
  end

  @doc """
  Updates a module.
  """
  def update_module(%Module{} = module, attrs) do
    module
    |> Module.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a module.
  """
  def delete_module(%Module{} = module) do
    Repo.delete(module)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking module changes.
  """
  def change_module(%Module{} = module, attrs \\ %{}) do
    Module.changeset(module, attrs)
  end

  ## Composable Queries

  @doc """
  Returns modules belonging to a specific goal category.
  """
  def list_modules_by_goal_category(goal_category_id) do
    Module
    |> by_goal_category(goal_category_id)
    |> order_by(:title)
    |> preload([:protocols, :goal_categories])
    |> Repo.all()
  end

  @doc """
  Returns modules assigned to a specific Power Pillar (either pillar_1 or pillar_2).
  """
  def list_modules_by_power_pillar(power_pillar) do
    Module
    |> by_power_pillar(power_pillar)
    |> order_by(:title)
    |> preload([:protocols, :goal_categories])
    |> Repo.all()
  end

  @doc """
  Filters modules by multiple criteria.

  Accepts a map with optional keys:
  - `:goal_category_id` - filter by goal category
  - `:power_pillar` - filter by Power Pillar
  - `:intensity` - filter by intensity level
  - `:daily_time` - filter by max daily time (minutes)
  - `:weekly_freq` - filter by max weekly frequency
  - `:lead_time_fit` - filter by lead time fit
  - `:module_type` - filter by module type
  - `:contributor` - filter by contributor name
  """
  def filter_modules(criteria \\ %{}) do
    Module
    |> apply_filters(criteria)
    |> order_by(:title)
    |> preload([:protocols, :goal_categories])
    |> Repo.all()
  end

  @filter_handlers %{
    goal_category_id: &__MODULE__.by_goal_category/2,
    power_pillar: &__MODULE__.by_power_pillar/2,
    intensity: &__MODULE__.by_intensity/2,
    daily_time: &__MODULE__.by_max_daily_time/2,
    weekly_freq: &__MODULE__.by_max_weekly_freq/2,
    lead_time_fit: &__MODULE__.by_lead_time_fit/2,
    module_type: &__MODULE__.by_module_type/2,
    contributor: &__MODULE__.by_contributor/2
  }

  defp apply_filters(query, criteria) do
    Enum.reduce(criteria, query, fn {key, value}, q ->
      case Map.get(@filter_handlers, key) do
        nil -> q
        handler -> handler.(q, value)
      end
    end)
  end

  @doc false
  def by_goal_category(query, goal_category_id) do
    from m in query,
      join: mgc in "modules_goal_categories",
      on: mgc.module_id == m.id,
      where: mgc.goal_category_id == ^goal_category_id
  end

  @doc false
  def by_power_pillar(query, power_pillar) do
    pillar_string = to_string(power_pillar)

    from m in query,
      where: m.power_pillar_1 == ^pillar_string or m.power_pillar_2 == ^pillar_string
  end

  @doc false
  def by_intensity(query, intensity) do
    intensity_string = to_string(intensity)
    from m in query, where: m.intensity == ^intensity_string
  end

  @doc false
  def by_max_daily_time(query, max_time) do
    from m in query, where: is_nil(m.daily_time) or m.daily_time <= ^max_time
  end

  @doc false
  def by_max_weekly_freq(query, max_freq) do
    from m in query, where: is_nil(m.weekly_freq) or m.weekly_freq <= ^max_freq
  end

  @doc false
  def by_lead_time_fit(query, fit) do
    fit_string = to_string(fit)
    from m in query, where: m.lead_time_fit == ^fit_string
  end

  @doc false
  def by_module_type(query, type) do
    type_string = to_string(type)
    from m in query, where: m.module_type == ^type_string
  end

  @doc false
  def by_contributor(query, contributor) do
    from m in query, where: m.contributor == ^contributor
  end

  ## Completeness

  @completeness_fields [
    :overview,
    :core_concepts,
    :power_pillar_1,
    :outcomes,
    :modifications,
    :coach_tip,
    :intensity,
    :daily_time,
    :weekly_freq,
    :lead_time_fit,
    :module_type
  ]

  @doc """
  Returns a completeness percentage and list of missing fields for a module.
  """
  def module_completeness(%Module{} = module) do
    total = length(@completeness_fields)

    filled =
      Enum.count(@completeness_fields, fn field ->
        value = Map.get(module, field)
        value != nil and value != ""
      end)

    missing =
      @completeness_fields
      |> Enum.reject(fn field ->
        value = Map.get(module, field)
        value != nil and value != ""
      end)
      |> Enum.map(&to_string/1)

    {round(filled / total * 100), missing}
  end

  @doc """
  Returns the list of unique contributors across all modules.
  """
  def list_contributors do
    Module
    |> select([m], m.contributor)
    |> distinct(true)
    |> order_by(:contributor)
    |> Repo.all()
  end

  ## Protocols

  @doc """
  Creates a protocol for a module.
  """
  def create_protocol(attrs \\ %{}) do
    %Protocol{}
    |> Protocol.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists protocols for a given module, ordered by position.
  """
  def list_protocols_for_module(module_id) do
    Protocol
    |> where([p], p.module_id == ^module_id)
    |> order_by(:position)
    |> Repo.all()
  end
end
