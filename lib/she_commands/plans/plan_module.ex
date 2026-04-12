defmodule SheCommands.Plans.PlanModule do
  @moduledoc """
  Schema for plan-module associations.

  Tracks which modules are included in a plan, their Power Pillar
  assignment, and display ordering.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias SheCommands.Modules.Module
  alias SheCommands.Plans.Plan

  @power_pillars [:power_up, :power_through, :power_down, :empower]

  def power_pillars, do: @power_pillars

  schema "plan_modules" do
    belongs_to :plan, Plan
    belongs_to :module, Module

    field :power_pillar, Ecto.Enum, values: @power_pillars
    field :position, :integer

    timestamps(type: :utc_datetime)
  end

  @required_fields [:plan_id, :module_id, :power_pillar, :position]

  def changeset(plan_module, attrs) do
    plan_module
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:position, greater_than: 0)
    |> foreign_key_constraint(:plan_id)
    |> foreign_key_constraint(:module_id)
    |> unique_constraint([:plan_id, :position])
  end
end
