defmodule SheCommands.Chat do
  @moduledoc """
  The Chat context.

  Manages chat message persistence for conversations between users
  and the AI assistant, scoped to a user's plan.
  """

  import Ecto.Query, warn: false

  alias SheCommands.Chat.ChatMessage
  alias SheCommands.Repo

  @default_max_message_length 2000
  @default_rate_limit_count 20
  @default_rate_limit_window_seconds 300

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

  @doc """
  Validates message content length.

  Returns `:ok` if within limits, `{:error, :message_too_long}` otherwise.
  """
  def validate_message_length(content) when is_binary(content) do
    max =
      Application.get_env(:she_commands, :chat_max_message_length, @default_max_message_length)

    if String.length(content) <= max do
      :ok
    else
      {:error, :message_too_long}
    end
  end

  def validate_message_length(_), do: {:error, :message_too_long}

  @doc """
  Checks if a user has exceeded the rate limit for sending messages.

  Returns `:ok` if under the limit, `{:error, :rate_limited}` otherwise.
  Counts user messages (role: :user) within the configured time window.
  """
  def check_rate_limit(user_id) do
    max_count =
      Application.get_env(:she_commands, :chat_rate_limit_count, @default_rate_limit_count)

    window_seconds =
      Application.get_env(
        :she_commands,
        :chat_rate_limit_window_seconds,
        @default_rate_limit_window_seconds
      )

    cutoff = DateTime.add(DateTime.utc_now(), -window_seconds, :second)

    count =
      ChatMessage
      |> where([m], m.user_id == ^user_id and m.role == :user and m.inserted_at >= ^cutoff)
      |> Repo.aggregate(:count)

    if count < max_count do
      :ok
    else
      {:error, :rate_limited}
    end
  end
end
