defmodule SheCommands.Chat.ChatMessage do
  @moduledoc """
  Schema for chat messages.

  A chat message stores a single turn in a conversation between a user
  and the AI assistant, scoped to a specific plan.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias SheCommands.Accounts.User
  alias SheCommands.Plans.Plan

  @roles [:user, :assistant]

  def roles, do: @roles

  schema "chat_messages" do
    belongs_to :user, User
    belongs_to :plan, Plan

    field :role, Ecto.Enum, values: @roles
    field :content, :string

    timestamps(type: :utc_datetime)
  end

  @required_fields [:user_id, :plan_id, :role, :content]

  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:plan_id)
  end
end
