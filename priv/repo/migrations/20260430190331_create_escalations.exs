defmodule SheCommands.Repo.Migrations.CreateEscalations do
  use Ecto.Migration

  def change do
    create table(:escalations) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :plan_id, references(:plans, on_delete: :nilify_all)
      add :chat_message_id, references(:chat_messages, on_delete: :nilify_all)
      add :coach_id, references(:users, on_delete: :nilify_all)

      add :status, :string, null: false, default: "pending"
      add :subject, :string, null: false
      add :user_note, :text
      add :coach_response, :text
      add :responded_at, :utc_datetime
      add :sla_deadline, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:escalations, [:user_id])
    create index(:escalations, [:plan_id])
    create index(:escalations, [:chat_message_id])
    create index(:escalations, [:coach_id])
    create index(:escalations, [:status])
  end
end
