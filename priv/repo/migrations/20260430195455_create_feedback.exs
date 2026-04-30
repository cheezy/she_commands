defmodule SheCommands.Repo.Migrations.CreateFeedback do
  use Ecto.Migration

  def change do
    create table(:feedback_prompts) do
      add :plan_id, references(:plans, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :prompt_type, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :scheduled_for, :utc_datetime
      add :sent_at, :utc_datetime
      add :responded_at, :utc_datetime
      add :response, :text

      timestamps(type: :utc_datetime)
    end

    create index(:feedback_prompts, [:plan_id])
    create index(:feedback_prompts, [:user_id])
    create index(:feedback_prompts, [:status])

    create table(:feedback_surveys) do
      add :plan_id, references(:plans, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :survey_type, :string, null: false
      add :responses, :map, default: %{}
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:feedback_surveys, [:plan_id])
    create index(:feedback_surveys, [:user_id])
  end
end
