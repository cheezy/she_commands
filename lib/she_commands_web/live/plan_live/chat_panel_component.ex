defmodule SheCommandsWeb.PlanLive.ChatPanelComponent do
  @moduledoc """
  LiveComponent for the chat panel in the plan view.

  A self-contained presentation component that renders a floating chat
  drawer with message list, text input, typing indicator, and empty
  state with suggested questions. All state and data operations are
  owned by the parent LiveView.
  """

  use SheCommandsWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="fixed bottom-6 right-6 z-40 flex flex-col items-end gap-3">
      <%!-- Chat Panel --%>
      <div
        :if={@open}
        class="w-80 sm:w-96 flex flex-col border border-base-content/10 bg-base-100
               max-h-[calc(100vh-8rem)]"
      >
        <%!-- Header --%>
        <div class="px-4 py-3 border-b border-base-content/10 flex items-center justify-between shrink-0">
          <span class="font-label text-xs uppercase tracking-[0.25em] text-base-content/50">
            {gettext("Chat")}
          </span>
          <button
            phx-click="toggle_chat"
            class="text-base-content/40 hover:text-base-content transition cursor-pointer"
            aria-label={gettext("Close chat")}
          >
            <.icon name="hero-x-mark" class="size-4" />
          </button>
        </div>

        <%!-- Messages area --%>
        <div
          id="chat-messages"
          phx-hook="ChatScroll"
          class="flex-1 overflow-y-auto p-4 space-y-3 min-h-0"
        >
          <%!-- Empty state --%>
          <div :if={@messages == []}>
            <p class="text-sm text-base-content/50 font-serif italic mb-4">
              {gettext("Hi! I'm your plan assistant. Ask me anything about your plan.")}
            </p>
            <div class="space-y-2">
              <button
                :for={q <- suggested_questions()}
                phx-click="suggest_question"
                phx-value-question={q}
                class="block w-full text-left border border-base-content/10 px-3 py-2
                       text-xs text-base-content/60 hover:bg-base-200 transition cursor-pointer"
              >
                {q}
              </button>
            </div>
          </div>

          <%!-- Messages --%>
          <div
            :for={msg <- @messages}
            class={
              if msg.role == :user,
                do: "ml-8 p-3 bg-base-200",
                else: "mr-8 p-3 bg-base-300"
            }
          >
            <p class="text-sm text-base-content/70 leading-relaxed whitespace-pre-wrap break-words">
              {msg.content}
            </p>
          </div>

          <%!-- Typing indicator --%>
          <div :if={@loading} class="mr-8 p-3 bg-base-300 flex items-center gap-1.5">
            <span class="size-1.5 bg-base-content/30 rounded-full animate-bounce [animation-delay:0ms]" />
            <span class="size-1.5 bg-base-content/30 rounded-full animate-bounce [animation-delay:150ms]" />
            <span class="size-1.5 bg-base-content/30 rounded-full animate-bounce [animation-delay:300ms]" />
          </div>

          <%!-- Error state --%>
          <div :if={@error} class="mr-8 p-3 border border-error/20 bg-error/5">
            <p class="text-sm text-error/80 mb-2">
              {gettext("Something went wrong. Please try again.")}
            </p>
            <button
              phx-click="retry_message"
              class="text-xs text-error/70 underline hover:no-underline cursor-pointer"
            >
              {gettext("Retry")}
            </button>
          </div>
        </div>

        <%!-- Input form --%>
        <form
          phx-submit="send_message"
          class="border-t border-base-content/10 p-3 flex gap-2 shrink-0"
        >
          <input
            type="text"
            name="message"
            placeholder={gettext("Ask about your plan...")}
            autocomplete="off"
            value=""
            class="flex-1 bg-base-200 border border-base-content/10 px-3 py-2 text-sm
                   text-base-content placeholder:text-base-content/30
                   focus:outline-none focus:border-base-content/30"
          />
          <button
            type="submit"
            class="text-base-content/50 hover:text-base-content transition cursor-pointer p-2"
            aria-label={gettext("Send")}
          >
            <.icon name="hero-paper-airplane" class="size-4" />
          </button>
        </form>
      </div>

      <%!-- Toggle button (always visible) --%>
      <button
        phx-click="toggle_chat"
        class="bg-base-200 border border-base-content/10 p-3
               hover:bg-base-300 transition cursor-pointer"
        aria-label={if @open, do: gettext("Close chat"), else: gettext("Open chat")}
      >
        <.icon name="hero-chat-bubble-left-right" class="size-5 text-base-content/70" />
      </button>
    </div>
    """
  end

  defp suggested_questions do
    [
      gettext("What should I focus on today?"),
      gettext("Explain my Power Up modules"),
      gettext("How do I modify exercises for my level?")
    ]
  end
end
