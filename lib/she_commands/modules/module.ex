defmodule SheCommands.Modules.Module do
  @moduledoc """
  Schema for the module library.

  Each module represents a self-contained training or coaching unit with
  protocols, Power Pillar assignments, goal category tags, and metadata
  used by the logic engine to assemble personalized plans.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias SheCommands.Intake.GoalCategory
  alias SheCommands.Modules.Protocol

  @power_pillars [:power_up, :power_through, :power_down, :empower]
  @intensities [:low, :moderate, :high]
  @module_types [:foundational, :secondary, :assisted, :bespoke]
  @lead_time_fits [:short, :medium, :long]

  def power_pillars, do: @power_pillars
  def intensities, do: @intensities
  def module_types, do: @module_types
  def lead_time_fits, do: @lead_time_fits

  schema "modules" do
    field :module_id, :string
    field :contributor, :string
    field :title, :string
    field :overview, :string
    field :core_concepts, :string
    field :power_pillar_1, Ecto.Enum, values: @power_pillars
    field :power_pillar_2, Ecto.Enum, values: @power_pillars
    field :module_type, Ecto.Enum, values: @module_types, default: :foundational
    field :outcomes, :string
    field :protocol_sequencing, :string
    field :modifications, :string
    field :time_to_result, :string
    field :experience_level, :string
    field :intensity, Ecto.Enum, values: @intensities, default: :moderate
    field :daily_time, :integer
    field :weekly_freq, :integer
    field :daily_freq, :integer
    field :coach_tip, :string
    field :coach_tip_attribution, :string
    field :video_available, :boolean, default: false
    field :sources, :string
    field :reward_eligible, :boolean, default: false
    field :complementary_module_ids, {:array, :integer}, default: []
    field :outcome_keywords, {:array, :string}, default: []
    field :lead_time_fit, Ecto.Enum, values: @lead_time_fits, default: :medium

    has_many :protocols, Protocol

    many_to_many :goal_categories, GoalCategory,
      join_through: "modules_goal_categories",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @required_fields [:module_id, :contributor, :title, :power_pillar_1]
  @optional_fields [
    :overview,
    :core_concepts,
    :power_pillar_2,
    :module_type,
    :outcomes,
    :protocol_sequencing,
    :modifications,
    :time_to_result,
    :experience_level,
    :intensity,
    :daily_time,
    :weekly_freq,
    :daily_freq,
    :coach_tip,
    :coach_tip_attribution,
    :video_available,
    :sources,
    :reward_eligible,
    :complementary_module_ids,
    :outcome_keywords,
    :lead_time_fit
  ]

  def changeset(module, attrs) do
    module
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, max: 500)
    |> validate_length(:contributor, max: 200)
    |> unique_constraint(:module_id)
  end
end
