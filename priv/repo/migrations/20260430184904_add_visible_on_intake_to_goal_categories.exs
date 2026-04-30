defmodule SheCommands.Repo.Migrations.AddVisibleOnIntakeToGoalCategories do
  use Ecto.Migration

  def change do
    alter table(:goal_categories) do
      add :visible_on_intake, :boolean, null: false, default: true
    end
  end
end
