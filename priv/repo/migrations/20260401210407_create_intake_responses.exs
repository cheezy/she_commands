defmodule SheCommands.Repo.Migrations.CreateIntakeResponses do
  use Ecto.Migration

  def change do
    create table(:goal_categories) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :outcome_power_up, :text
      add :outcome_power_through, :text
      add :outcome_power_down, :text
      add :outcome_empower, :text
      add :position, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:goal_categories, [:slug])

    create table(:intake_responses) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "in_progress"

      # Goal fields
      add :goal_intent, :text
      add :goal_category_id, references(:goal_categories, on_delete: :nilify_all)
      add :lead_time, :string

      # Availability fields
      add :days_per_week, :integer
      add :hours_per_day, :string
      add :intensity, :string

      # Preferences
      add :limitations, {:array, :string}, default: []
      add :limitations_notes, :text
      add :coaching_preference, :string

      # Current regimen
      add :fitness_regimen, :string
      add :fitness_regimen_notes, :text
      add :personal_dev_regimen, :string
      add :personal_dev_regimen_notes, :text

      # Location
      add :city, :string
      add :province, :string
      add :country, :string

      # Feedback
      add :feedback_interest, :boolean, default: false

      # Progress tracking
      add :current_step, :integer, default: 1
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:intake_responses, [:user_id])
    create index(:intake_responses, [:status])
    create index(:intake_responses, [:goal_category_id])
  end
end
