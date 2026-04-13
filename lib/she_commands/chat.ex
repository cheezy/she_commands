defmodule SheCommands.Chat do
  @moduledoc """
  The Chat context.

  Manages chat message persistence for conversations between users
  and the AI assistant, scoped to a user's plan.
  """

  import Ecto.Query, warn: false

  alias SheCommands.Chat.ChatMessage
  alias SheCommands.Repo

  @doc """
  Creates a chat message.

  ## Examples

      iex> create_message(%{role: :user, content: "Hello", user_id: 1, plan_id: 1})
      {:ok, %ChatMessage{}}

      iex> create_message(%{})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %ChatMessage{}
    |> ChatMessage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists chat messages for a plan, scoped to a specific user.

  Returns messages in chronological order (oldest first).
  """
  def list_messages_for_plan(plan_id, user_id) do
    ChatMessage
    |> where([m], m.plan_id == ^plan_id and m.user_id == ^user_id)
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
  end

  @doc """
  Deletes all chat messages for a user's plan conversation.

  Returns `{count, nil}` where count is the number of deleted messages.
  """
  def clear_conversation(plan_id, user_id) do
    ChatMessage
    |> where([m], m.plan_id == ^plan_id and m.user_id == ^user_id)
    |> Repo.delete_all()
  end
end
