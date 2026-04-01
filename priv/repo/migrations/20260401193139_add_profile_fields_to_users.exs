defmodule SheCommands.Repo.Migrations.AddProfileFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Profile fields
      add :display_name, :string
      add :city, :string
      add :province, :string
      add :country, :string

      # Coach-specific fields
      add :bio, :text
      add :specialty, :string
      add :credential, :string
    end
  end
end
