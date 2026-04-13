defmodule SheCommands.ChatFixtures do
  @moduledoc """
  Test helpers for creating entities via the `SheCommands.Chat` context.
  """

  import SheCommands.AccountsFixtures
  import SheCommands.PlansFixtures

  alias SheCommands.Chat

  def chat_message_fixture(attrs \\ %{}) do
    user = attrs[:user] || user_fixture()
    plan = attrs[:plan] || plan_fixture(%{user: user})

    {:ok, message} =
      attrs
      |> Enum.into(%{
        user_id: user.id,
        plan_id: plan.id,
        role: :user,
        content: "Test message content"
      })
      |> Chat.create_message()

    message
  end
end
