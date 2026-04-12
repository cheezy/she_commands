defmodule SheCommands.Repo.Migrations.CreatePlans do
  use Ecto.Migration

  def change do
    create table(:plans) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :intake_response_id, references(:intake_responses, on_delete: :nilify_all)
      add :goal_category_id, references(:goal_categories, on_delete: :nilify_all)
      add :plan_type, :string, null: false
      add :status, :string, null: false, default: "generating"
      add :goal_statement, :text
      add :expected_outcomes, :text
      add :schedule, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:plans, [:user_id])
    create index(:plans, [:status])
    create index(:plans, [:intake_response_id])

    create table(:plan_modules) do
      add :plan_id, references(:plans, on_delete: :delete_all), null: false
      add :module_id, references(:modules, on_delete: :restrict), null: false
      add :power_pillar, :string, null: false
      add :position, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:plan_modules, [:plan_id])
    create unique_index(:plan_modules, [:plan_id, :position])
  end
end
