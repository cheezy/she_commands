defmodule SheCommands.Repo.Migrations.CreateModules do
  use Ecto.Migration

  def change do
    create table(:modules) do
      add :module_id, :string, null: false
      add :contributor, :string, null: false
      add :title, :string, null: false
      add :overview, :text
      add :core_concepts, :text
      add :power_pillar_1, :string, null: false
      add :power_pillar_2, :string
      add :module_type, :string, null: false, default: "foundational"
      add :outcomes, :text
      add :protocol_sequencing, :text
      add :modifications, :text
      add :time_to_result, :string
      add :experience_level, :string
      add :intensity, :string, null: false, default: "moderate"
      add :daily_time, :integer
      add :weekly_freq, :integer
      add :daily_freq, :integer
      add :coach_tip, :text
      add :coach_tip_attribution, :string
      add :video_available, :boolean, default: false, null: false
      add :sources, :text
      add :reward_eligible, :boolean, default: false, null: false
      add :complementary_module_ids, {:array, :integer}, default: []
      add :outcome_keywords, {:array, :string}, default: []
      add :lead_time_fit, :string, null: false, default: "medium"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:modules, [:module_id])
    create index(:modules, [:power_pillar_1])
    create index(:modules, [:intensity])
    create index(:modules, [:module_type])
    create index(:modules, [:lead_time_fit])

    create table(:protocols) do
      add :module_id, references(:modules, on_delete: :delete_all), null: false
      add :position, :integer, null: false
      add :purpose, :text, null: false
      add :steps, :text, null: false
      add :prescription, :text, null: false
      add :expected_outcome, :text

      timestamps(type: :utc_datetime)
    end

    create index(:protocols, [:module_id])
    create unique_index(:protocols, [:module_id, :position])

    create table(:modules_goal_categories, primary_key: false) do
      add :module_id, references(:modules, on_delete: :delete_all), null: false
      add :goal_category_id, references(:goal_categories, on_delete: :delete_all), null: false
    end

    create unique_index(:modules_goal_categories, [:module_id, :goal_category_id])
    create index(:modules_goal_categories, [:goal_category_id])
  end
end
