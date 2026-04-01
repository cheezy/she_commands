defmodule SheCommands.Intake.GoalCategory do
  @moduledoc """
  Schema for goal categories.

  Goal categories are extensible — new categories can be added via database
  inserts without code changes. Each category has outcome descriptions per
  Power Pillar used in plan output.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "goal_categories" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :outcome_power_up, :string
    field :outcome_power_through, :string
    field :outcome_power_down, :string
    field :outcome_empower, :string
    field :position, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  def changeset(goal_category, attrs) do
    goal_category
    |> cast(attrs, [
      :name,
      :slug,
      :description,
      :outcome_power_up,
      :outcome_power_through,
      :outcome_power_down,
      :outcome_empower,
      :position
    ])
    |> validate_required([:name, :slug])
    |> validate_length(:name, max: 200)
    |> unique_constraint(:slug)
  end
end
