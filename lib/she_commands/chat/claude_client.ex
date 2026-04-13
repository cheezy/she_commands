defmodule SheCommands.Chat.ClaudeClient do
  @moduledoc """
  Client for the Anthropic Claude Messages API using Req.
  """

  @messages_url "https://api.anthropic.com/v1/messages"
  @default_model "claude-sonnet-4-20250514"
  @default_max_tokens 1024
  @anthropic_version "2023-06-01"

  @doc """
  Sends messages to the Claude Messages API and returns the assistant response.

  ## Parameters

    * `messages` - A list of message maps with `:role` and `:content` keys.
    * `opts` - Keyword options:
      * `:system` - System prompt string (optional)
      * `:model` - Model identifier (defaults to `#{@default_model}`)
      * `:max_tokens` - Maximum tokens in response (defaults to #{@default_max_tokens})

  ## Returns

    * `{:ok, content}` on success where `content` is the assistant's text response
    * `{:error, reason}` on failure

  ## Examples

      iex> messages = [%{role: "user", content: "Hello"}]
      iex> SheCommands.Chat.ClaudeClient.send_message(messages, system: "You are helpful.")
      {:ok, "Hello! How can I help you today?"}

  """
  @spec send_message(list(map()), keyword()) ::
          {:ok, String.t()} | {:error, atom() | String.t()}
  def send_message(messages, opts \\ [])
  def send_message([], _opts), do: {:error, :empty_messages}

  def send_message(messages, opts) do
    with {:ok, api_key} <- fetch_api_key(),
         {:ok, body} <- build_request_body(messages, opts),
         {:ok, response} <- do_request(api_key, body) do
      parse_response(response)
    end
  end

  @doc """
  Formats a list of `ChatMessage` structs into the Claude API message format.

  ## Parameters

    * `chat_messages` - A list of maps or structs with `:role` and `:content` fields.

  ## Returns

  A list of maps with string `"role"` and `"content"` keys.
  """
  @spec format_messages(list(map())) :: list(map())
  def format_messages(chat_messages) do
    Enum.map(chat_messages, fn msg ->
      %{"role" => to_string(msg.role), "content" => to_string(msg.content)}
    end)
  end

  defp fetch_api_key do
    case Application.get_env(:she_commands, :anthropic_api_key) do
      nil -> {:error, :missing_api_key}
      "" -> {:error, :missing_api_key}
      key -> {:ok, key}
    end
  end

  defp build_request_body(messages, opts) do
    formatted = format_messages(messages)
    model = Keyword.get(opts, :model, @default_model)
    max_tokens = Keyword.get(opts, :max_tokens, @default_max_tokens)

    body =
      %{"model" => model, "max_tokens" => max_tokens, "messages" => formatted}
      |> maybe_add_system(Keyword.get(opts, :system))

    {:ok, body}
  end

  defp maybe_add_system(body, nil), do: body
  defp maybe_add_system(body, ""), do: body
  defp maybe_add_system(body, system), do: Map.put(body, "system", system)

  defp do_request(api_key, body) do
    req_options = Application.get_env(:she_commands, :claude_req_options, [])

    [
      url: @messages_url,
      json: body,
      headers: [
        {"x-api-key", api_key},
        {"anthropic-version", @anthropic_version},
        {"content-type", "application/json"}
      ],
      receive_timeout: 30_000
    ]
    |> Keyword.merge(req_options)
    |> Req.post()
    |> case do
      {:ok, response} -> {:ok, response}
      {:error, %Req.TransportError{reason: :timeout}} -> {:error, :timeout}
      {:error, exception} -> {:error, Exception.message(exception)}
    end
  end

  defp parse_response(%Req.Response{status: 200, body: body}) do
    case body do
      %{"content" => [%{"text" => text} | _]} ->
        {:ok, text}

      _ ->
        {:error, :unexpected_response_format}
    end
  end

  defp parse_response(%Req.Response{status: 429}) do
    {:error, :rate_limited}
  end

  defp parse_response(%Req.Response{status: status, body: body}) when status >= 400 do
    message = get_in(body, ["error", "message"]) || "API error: #{status}"
    {:error, message}
  end

  defp parse_response(%Req.Response{status: status}) do
    {:error, "Unexpected status: #{status}"}
  end
end
