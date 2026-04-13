defmodule SheCommands.ChatTest do
  use SheCommands.DataCase, async: true

  import SheCommands.AccountsFixtures
  import SheCommands.ChatFixtures
  import SheCommands.PlansFixtures

  alias SheCommands.Chat
  alias SheCommands.Chat.ChatMessage

  describe "ChatMessage.roles/0" do
    test "returns available roles" do
      assert ChatMessage.roles() == [:user, :assistant]
    end
  end

  describe "create_message/1" do
    test "creates a user message with valid attrs" do
      user = user_fixture()
      plan = plan_fixture(%{user: user})

      attrs = %{user_id: user.id, plan_id: plan.id, role: :user, content: "Hello"}
      assert {:ok, message} = Chat.create_message(attrs)
      assert message.role == :user
      assert message.content == "Hello"
      assert message.user_id == user.id
      assert message.plan_id == plan.id
    end

    test "creates an assistant message with valid attrs" do
      user = user_fixture()
      plan = plan_fixture(%{user: user})

      attrs = %{user_id: user.id, plan_id: plan.id, role: :assistant, content: "Hi there"}
      assert {:ok, message} = Chat.create_message(attrs)
      assert message.role == :assistant
      assert message.content == "Hi there"
    end

    test "returns error changeset with invalid attrs" do
      assert {:error, changeset} = Chat.create_message(%{})
      assert %{role: ["can't be blank"]} = errors_on(changeset)
      assert %{content: ["can't be blank"]} = errors_on(changeset)
      assert %{user_id: ["can't be blank"]} = errors_on(changeset)
      assert %{plan_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error with invalid role" do
      user = user_fixture()
      plan = plan_fixture(%{user: user})

      attrs = %{user_id: user.id, plan_id: plan.id, role: :invalid, content: "Hello"}
      assert {:error, changeset} = Chat.create_message(attrs)
      assert %{role: ["is invalid"]} = errors_on(changeset)
    end

    test "handles very long message content" do
      user = user_fixture()
      plan = plan_fixture(%{user: user})
      long_content = String.duplicate("a", 15_000)

      attrs = %{user_id: user.id, plan_id: plan.id, role: :user, content: long_content}
      assert {:ok, message} = Chat.create_message(attrs)
      assert String.length(message.content) == 15_000
    end
  end

  describe "list_messages_for_plan/2" do
    test "returns messages scoped to user and plan" do
      user = user_fixture()
      plan = plan_fixture(%{user: user})

      {:ok, msg} =
        Chat.create_message(%{user_id: user.id, plan_id: plan.id, role: :user, content: "Hello"})

      messages = Chat.list_messages_for_plan(plan.id, user.id)
      assert [returned] = messages
      assert returned.id == msg.id
    end

    test "returns messages in chronological order" do
      user = user_fixture()
      plan = plan_fixture(%{user: user})

      {:ok, first} =
        Chat.create_message(%{
          user_id: user.id,
          plan_id: plan.id,
          role: :user,
          content: "First"
        })

      {:ok, second} =
        Chat.create_message(%{
          user_id: user.id,
          plan_id: plan.id,
          role: :assistant,
          content: "Second"
        })

      messages = Chat.list_messages_for_plan(plan.id, user.id)
      assert [m1, m2] = messages
      assert m1.id == first.id
      assert m2.id == second.id
    end

    test "does not return messages from other users (data isolation)" do
      user_a = user_fixture()
      user_b = user_fixture()
      plan = plan_fixture(%{user: user_a})

      Chat.create_message(%{
        user_id: user_a.id,
        plan_id: plan.id,
        role: :user,
        content: "User A message"
      })

      assert Chat.list_messages_for_plan(plan.id, user_b.id) == []
    end

    test "does not return messages from other plans" do
      user = user_fixture()
      plan_a = plan_fixture(%{user: user})
      plan_b = plan_fixture(%{user: user})

      Chat.create_message(%{
        user_id: user.id,
        plan_id: plan_a.id,
        role: :user,
        content: "Plan A message"
      })

      assert Chat.list_messages_for_plan(plan_b.id, user.id) == []
    end

    test "returns empty list when no messages exist" do
      user = user_fixture()
      plan = plan_fixture(%{user: user})

      assert Chat.list_messages_for_plan(plan.id, user.id) == []
    end
  end

  describe "clear_conversation/2" do
    test "deletes all messages for a user's plan conversation" do
      user = user_fixture()
      plan = plan_fixture(%{user: user})

      Chat.create_message(%{
        user_id: user.id,
        plan_id: plan.id,
        role: :user,
        content: "Message 1"
      })

      Chat.create_message(%{
        user_id: user.id,
        plan_id: plan.id,
        role: :assistant,
        content: "Message 2"
      })

      assert {2, nil} = Chat.clear_conversation(plan.id, user.id)
      assert Chat.list_messages_for_plan(plan.id, user.id) == []
    end

    test "does not delete messages from other users" do
      user_a = user_fixture()
      user_b = user_fixture()
      plan = plan_fixture(%{user: user_a})

      Chat.create_message(%{
        user_id: user_a.id,
        plan_id: plan.id,
        role: :user,
        content: "User A"
      })

      Chat.create_message(%{
        user_id: user_b.id,
        plan_id: plan.id,
        role: :user,
        content: "User B"
      })

      Chat.clear_conversation(plan.id, user_a.id)

      assert Chat.list_messages_for_plan(plan.id, user_a.id) == []
      assert [_] = Chat.list_messages_for_plan(plan.id, user_b.id)
    end

    test "returns {0, nil} when no messages to clear" do
      user = user_fixture()
      plan = plan_fixture(%{user: user})

      assert {0, nil} = Chat.clear_conversation(plan.id, user.id)
    end
  end

  describe "integration" do
    test "full create-list-clear cycle" do
      user = user_fixture()
      plan = plan_fixture(%{user: user})

      {:ok, _} =
        Chat.create_message(%{
          user_id: user.id,
          plan_id: plan.id,
          role: :user,
          content: "Hello"
        })

      {:ok, _} =
        Chat.create_message(%{
          user_id: user.id,
          plan_id: plan.id,
          role: :assistant,
          content: "Hi there"
        })

      messages = Chat.list_messages_for_plan(plan.id, user.id)
      assert length(messages) == 2
      assert Enum.map(messages, & &1.role) == [:user, :assistant]

      {2, nil} = Chat.clear_conversation(plan.id, user.id)
      assert Chat.list_messages_for_plan(plan.id, user.id) == []
    end
  end

  describe "validate_message_length/1" do
    test "accepts message within limit" do
      assert :ok = Chat.validate_message_length("Hello")
    end

    test "accepts message at exact limit" do
      content = String.duplicate("a", 2000)
      assert :ok = Chat.validate_message_length(content)
    end

    test "rejects message over limit" do
      content = String.duplicate("a", 2001)
      assert {:error, :message_too_long} = Chat.validate_message_length(content)
    end

    test "rejects non-binary input" do
      assert {:error, :message_too_long} = Chat.validate_message_length(nil)
    end
  end

  describe "check_rate_limit/1" do
    test "allows messages under threshold" do
      user = user_fixture()
      plan = plan_fixture(%{user: user})

      Chat.create_message(%{
        user_id: user.id,
        plan_id: plan.id,
        role: :user,
        content: "Hello"
      })

      assert :ok = Chat.check_rate_limit(user.id)
    end

    test "blocks messages over threshold" do
      user = user_fixture()
      plan = plan_fixture(%{user: user})

      # Set a low rate limit for testing
      Application.put_env(:she_commands, :chat_rate_limit_count, 2)

      on_exit(fn ->
        Application.delete_env(:she_commands, :chat_rate_limit_count)
      end)

      for _ <- 1..2 do
        Chat.create_message(%{
          user_id: user.id,
          plan_id: plan.id,
          role: :user,
          content: "Message"
        })
      end

      assert {:error, :rate_limited} = Chat.check_rate_limit(user.id)
    end

    test "does not count assistant messages" do
      user = user_fixture()
      plan = plan_fixture(%{user: user})

      Application.put_env(:she_commands, :chat_rate_limit_count, 2)

      on_exit(fn ->
        Application.delete_env(:she_commands, :chat_rate_limit_count)
      end)

      Chat.create_message(%{
        user_id: user.id,
        plan_id: plan.id,
        role: :user,
        content: "User msg"
      })

      Chat.create_message(%{
        user_id: user.id,
        plan_id: plan.id,
        role: :assistant,
        content: "Assistant msg"
      })

      assert :ok = Chat.check_rate_limit(user.id)
    end
  end

  describe "chat_message_fixture/1" do
    test "creates a message with defaults" do
      message = chat_message_fixture()
      assert message.role == :user
      assert message.content == "Test message content"
      assert message.user_id
      assert message.plan_id
    end

    test "allows overriding attrs" do
      message = chat_message_fixture(%{role: :assistant, content: "Custom content"})
      assert message.role == :assistant
      assert message.content == "Custom content"
    end
  end
end
