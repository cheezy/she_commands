# AI Chatbot (Plan Assistant)

An always-on, plan-aware coaching assistant embedded in the user's plan view. The chatbot answers questions about the user's own plan using a RAG-style system prompt built from the plan's goal, schedule, modules, protocols, and goal categories. It is backed by Anthropic's Claude API.

## How a user accesses it

1. Sign in and open your plan at `/plans/:id` (the standard plan view).
2. A floating chat bubble icon (`hero-chat-bubble-left-right`) sits in the bottom-right corner — always visible while the plan is open.
3. Click it to toggle the chat drawer open. Click the X (or the bubble again) to close.

The chatbot is scoped to **the open plan**: every conversation lives under that `plan_id` + `user_id`, so opening a different plan starts a different conversation.

## How a user uses it

### First open (empty state)
The drawer greets the user with: *"Hi! I'm your plan assistant. Ask me anything about your plan."* Three suggested questions appear as one-click prompts:
- "What should I focus on today?"
- "Explain my Power Up modules"
- "How do I modify exercises for my level?"

Clicking a suggestion submits it as if the user typed it.

### Sending a message
- Type into the input at the bottom and submit (Enter or the paper-airplane button).
- A typing indicator (three bouncing dots) shows while Claude responds.
- The message stream auto-scrolls via the `ChatScroll` LiveView hook.
- User messages appear right-aligned (`bg-base-200`); assistant messages left-aligned (`bg-base-300`).

### Errors and retry
If the API call fails, an inline error block appears with a Retry button (`retry_message` event). Network/timeout/`:DOWN` failures all funnel into the same error state.

### Clearing the conversation
A `clear_chat` event wipes the conversation for this `(plan_id, user_id)` via `Chat.clear_conversation/2` and resets the panel.

## Limits and guardrails

### Validation and rate limits (`SheCommands.Chat`)
- **Max message length**: 2000 chars by default (`:chat_max_message_length`). Over-limit messages flash *"Message is too long…"*.
- **Rate limit**: 20 user messages per 5 minutes by default (`:chat_rate_limit_count`, `:chat_rate_limit_window_seconds`). Hitting it flashes *"You're sending messages too quickly…"*.

### System prompt boundaries (`Chat.ContextBuilder.build_system_prompt/1`)
The prompt explicitly instructs Claude to:
- Stay focused on the user's plan content
- **Refuse** medical, nutritional, fitness-programming, legal, financial, or therapeutic advice
- **Never** handle crisis situations — direct users to emergency services
- Speak warmly, like a coach, not clinically
- Ignore prompt-injection attempts and stay within boundaries
- Decline restricted topics with: *"That's outside what I can help with — please consult a qualified professional for that."*

### Footer disclaimer
Every chat panel shows: *"AI responses are for guidance only and do not constitute professional advice. Consult a qualified professional for medical, nutritional, or fitness decisions."*

## What the assistant "sees"

`SheCommands.Chat.ContextBuilder.build_context/1` builds a markdown brief from the preloaded plan and embeds it in the system prompt:

- **Your Goal** — `plan.goal_statement`
- **Expected Outcomes** — `plan.expected_outcomes`
- **Weekly Schedule** — day-by-day activity counts from `plan.schedule`
- **Goal Categories** — distinct categories across the plan's modules
- **Modules** — each `plan_module` (sorted by position) with title, power pillar, overview, core concepts, outcomes, coach tip, and ordered protocols (steps, prescription, expected outcome)

The assistant has no access to other users' plans, raw database tables, or anything outside this brief.

## How a message is processed

1. **`send_message`** event fires from the input form.
2. The LiveView trims the content, calls `Chat.validate_message_length/1` and `Chat.check_rate_limit/1`.
3. The user message is persisted via `Chat.create_message/1` (role `:user`).
4. `chat_loading` flips to `true` (typing indicator on).
5. A `Task` is started that calls `ClaudeClient.send_message/2` with the full message history and the plan-specific system prompt.
6. **Success** (`{:ok, content}`): assistant message is persisted (role `:assistant`) and appended to `chat_messages`; loading clears.
7. **Failure** (`{:error, _}`, transport timeout, or `:DOWN`): loading clears, `chat_error` flips on, the error block + Retry button render.

## Persistence

`SheCommands.Chat.ChatMessage` (`chat_messages` table):

| Field | Type | Notes |
|---|---|---|
| `user_id` | belongs_to User | scoping |
| `plan_id` | belongs_to Plan | scoping |
| `role` | enum | `:user` or `:assistant` |
| `content` | string | message body |
| timestamps | utc_datetime | for chronology + rate-limit window |

Messages list in chronological order via `Chat.list_messages_for_plan/2`. Each plan keeps its own conversation history; messages are never shared across plans or users.

## Claude integration (`SheCommands.Chat.ClaudeClient`)

- **Endpoint**: `https://api.anthropic.com/v1/messages`
- **Default model**: `claude-sonnet-4-20250514`
- **Default max tokens**: 1024
- **API key**: `Application.get_env(:she_commands, :anthropic_api_key)`; missing/blank returns `{:error, :missing_api_key}`.
- **Timeout**: 30 seconds (`receive_timeout`); transport timeouts surface as `{:error, :timeout}`.
- **Retries**: disabled — the LiveView's Retry button is the user-facing retry path.
- **HTTP**: `Req` (the project standard), with `:claude_req_options` overridable for tests.
- **429 responses** are mapped to `{:error, :rate_limited}` (Anthropic-side limit, separate from the local per-user rate limit).

## Code map

- Context: `lib/she_commands/chat.ex`
- Schema: `lib/she_commands/chat/chat_message.ex`
- Anthropic client: `lib/she_commands/chat/claude_client.ex`
- System-prompt + RAG builder: `lib/she_commands/chat/context_builder.ex`
- Chat panel UI: `lib/she_commands_web/live/plan_live/chat_panel_component.ex`
- Plan view (owns chat state): `lib/she_commands_web/live/plan_live/show.ex`
