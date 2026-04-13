defmodule SheCommands.Chat.ClaudeClientTest do
  use ExUnit.Case, async: true

  alias SheCommands.Chat.ClaudeClient

  setup do
    Req.Test.set_req_test_from_context(%{req_test_stub: ClaudeClient})
    :ok
  end

  describe "send_message/2" do
    test "returns {:ok, content} on successful API call" do
      Req.Test.stub(ClaudeClient, fn conn ->
        assert conn.method == "POST"
        assert Plug.Conn.get_req_header(conn, "x-api-key") == ["test-api-key"]
        assert Plug.Conn.get_req_header(conn, "anthropic-version") == ["2023-06-01"]

        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "Hello! How can I help?"}],
          "model" => "claude-sonnet-4-20250514",
          "role" => "assistant"
        })
      end)

      messages = [%{role: "user", content: "Hello"}]
      assert {:ok, "Hello! How can I help?"} = ClaudeClient.send_message(messages)
    end

    test "formats request body correctly with system prompt and messages" do
      Req.Test.stub(ClaudeClient, fn conn ->
        {:ok, body, _conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert decoded["system"] == "You are a helpful assistant."
        assert decoded["model"] == "claude-sonnet-4-20250514"
        assert decoded["max_tokens"] == 1024
        assert decoded["messages"] == [%{"role" => "user", "content" => "Hi"}]

        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "Response"}]
        })
      end)

      messages = [%{role: "user", content: "Hi"}]

      assert {:ok, "Response"} =
               ClaudeClient.send_message(messages, system: "You are a helpful assistant.")
    end

    test "returns {:error, :rate_limited} on 429 response" do
      Req.Test.stub(ClaudeClient, fn conn ->
        conn
        |> Plug.Conn.put_status(429)
        |> Req.Test.json(%{"error" => %{"message" => "Rate limit exceeded"}})
      end)

      messages = [%{role: "user", content: "Hello"}]
      assert {:error, :rate_limited} = ClaudeClient.send_message(messages)
    end

    test "returns {:error, reason} on API failure (4xx)" do
      Req.Test.stub(ClaudeClient, fn conn ->
        conn
        |> Plug.Conn.put_status(400)
        |> Req.Test.json(%{"error" => %{"message" => "Invalid request"}})
      end)

      messages = [%{role: "user", content: "Hello"}]
      assert {:error, "Invalid request"} = ClaudeClient.send_message(messages)
    end

    test "returns {:error, reason} on API failure (5xx)" do
      Req.Test.stub(ClaudeClient, fn conn ->
        conn
        |> Plug.Conn.put_status(500)
        |> Req.Test.json(%{"error" => %{"message" => "Internal server error"}})
      end)

      messages = [%{role: "user", content: "Hello"}]
      assert {:error, "Internal server error"} = ClaudeClient.send_message(messages)
    end

    test "returns {:error, :empty_messages} when message list is empty" do
      assert {:error, :empty_messages} = ClaudeClient.send_message([], [])
    end

    test "returns {:error, :missing_api_key} when API key is nil" do
      original = Application.get_env(:she_commands, :anthropic_api_key)
      Application.put_env(:she_commands, :anthropic_api_key, nil)

      messages = [%{role: "user", content: "Hello"}]
      assert {:error, :missing_api_key} = ClaudeClient.send_message(messages)

      Application.put_env(:she_commands, :anthropic_api_key, original)
    end

    test "returns {:error, :missing_api_key} when API key is empty string" do
      original = Application.get_env(:she_commands, :anthropic_api_key)
      Application.put_env(:she_commands, :anthropic_api_key, "")

      messages = [%{role: "user", content: "Hello"}]
      assert {:error, :missing_api_key} = ClaudeClient.send_message(messages)

      Application.put_env(:she_commands, :anthropic_api_key, original)
    end

    test "sends request without system prompt when not provided" do
      Req.Test.stub(ClaudeClient, fn conn ->
        {:ok, body, _conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        refute Map.has_key?(decoded, "system")

        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "Response"}]
        })
      end)

      messages = [%{role: "user", content: "Hi"}]
      assert {:ok, "Response"} = ClaudeClient.send_message(messages)
    end

    test "returns error message for 4xx without error body structure" do
      Req.Test.stub(ClaudeClient, fn conn ->
        conn
        |> Plug.Conn.put_status(401)
        |> Req.Test.json(%{"unexpected" => "format"})
      end)

      messages = [%{role: "user", content: "Hello"}]
      assert {:error, "API error: 401"} = ClaudeClient.send_message(messages)
    end

    test "returns {:error, :unexpected_response_format} on malformed response" do
      Req.Test.stub(ClaudeClient, fn conn ->
        Req.Test.json(conn, %{"content" => []})
      end)

      messages = [%{role: "user", content: "Hello"}]
      assert {:error, :unexpected_response_format} = ClaudeClient.send_message(messages)
    end

    test "returns {:error, :timeout} on network timeout" do
      Req.Test.stub(ClaudeClient, fn conn ->
        Req.Test.transport_error(conn, :timeout)
      end)

      messages = [%{role: "user", content: "Hello"}]
      assert {:error, :timeout} = ClaudeClient.send_message(messages)
    end
  end

  describe "format_messages/1" do
    test "converts conversation history to Claude API format" do
      messages = [
        %{role: :user, content: "Hello"},
        %{role: :assistant, content: "Hi there!"},
        %{role: :user, content: "How are you?"}
      ]

      assert ClaudeClient.format_messages(messages) == [
               %{"role" => "user", "content" => "Hello"},
               %{"role" => "assistant", "content" => "Hi there!"},
               %{"role" => "user", "content" => "How are you?"}
             ]
    end

    test "handles string role values" do
      messages = [%{role: "user", content: "Hello"}]

      assert ClaudeClient.format_messages(messages) == [
               %{"role" => "user", "content" => "Hello"}
             ]
    end
  end
end
