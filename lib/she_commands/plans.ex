defmodule SheCommands.Plans do
  @moduledoc """
  The Plans context.

  Manages execution plans generated from intake responses and the
  module library. Plans contain selected modules organized by Power Pillar,
  a personalized goal statement, expected outcomes, and a weekly schedule.
  """

  import Ecto.Query, warn: false

  alias SheCommands.Plans.Plan
  alias SheCommands.Plans.PlanModule
  alias SheCommands.Repo

  ## Plans

  @doc """
  Returns the active plan for a user, preloading modules and their protocols.

  Returns `nil` if no active plan exists.
  """
  def get_active_plan_for_user(user_id) do
    Plan
    |> where([p], p.user_id == ^user_id and p.status == :active)
    |> order_by([p], desc: p.inserted_at)
    |> limit(1)
    |> preload(plan_modules: [module: [:protocols, :goal_categories]])
    |> Repo.one()
  end

  @doc """
  Gets a plan by ID, preloading all associations.

  Raises `Ecto.NoResultsError` if not found.
  """
  def get_plan!(id) do
    Plan
    |> preload(plan_modules: [module: [:protocols, :goal_categories]])
    |> Repo.get!(id)
  end

  @doc """
  Creates a plan.
  """
  def create_plan(attrs \\ %{}) do
    %Plan{}
    |> Plan.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a plan.
  """
  def update_plan(%Plan{} = plan, attrs) do
    plan
    |> Plan.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking plan changes.
  """
  def change_plan(%Plan{} = plan, attrs \\ %{}) do
    Plan.changeset(plan, attrs)
  end

  @doc """
  Lists all plans for a user, ordered by most recent first.
  """
  def list_plans_for_user(user_id) do
    Plan
    |> where([p], p.user_id == ^user_id)
    |> order_by([p], desc: p.inserted_at)
    |> preload(plan_modules: [module: [:protocols, :goal_categories]])
    |> Repo.all()
  end

  ## Plan Modules

  @doc """
  Adds a module to a plan.
  """
  def add_plan_module(attrs \\ %{}) do
    %PlanModule{}
    |> PlanModule.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists plan modules for a plan, ordered by position.
  """
  def list_plan_modules(plan_id) do
    PlanModule
    |> where([pm], pm.plan_id == ^plan_id)
    |> order_by(:position)
    |> preload(module: [:protocols, :goal_categories])
    |> Repo.all()
  end
end
