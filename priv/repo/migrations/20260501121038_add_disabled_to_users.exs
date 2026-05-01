defmodule SheCommands.Repo.Migrations.AddDisabledToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :disabled, :boolean, null: false, default: false
    end
  end
end
