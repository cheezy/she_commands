defmodule SheCommandsWeb.EscalationLive.MemberIndex do
  @moduledoc """
  Member-facing escalations page. Hosts the MemberComponent and forwards
  PubSub `:escalation_updated` messages to it so the component can refresh.
  """

  use SheCommandsWeb, :live_view

  alias SheCommands.Escalations
  alias SheCommandsWeb.EscalationLive.MemberComponent

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Escalations.subscribe_user(socket.assigns.current_scope.user.id)
    end

    {:ok, assign(socket, :page_title, gettext("Coach review"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="w-full max-w-2xl mx-auto py-12">
        <p class="font-label text-xs uppercase tracking-[0.25em] text-base-content/50 mb-3">
          {gettext("Support")}
        </p>
        <h1 class="text-3xl sm:text-4xl font-serif italic leading-[1.1] tracking-[-0.02em] text-base-content mb-8">
          {gettext("Coach review")}
        </h1>

        <.live_component
          module={MemberComponent}
          id="member-escalations"
          current_scope={@current_scope}
        />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_info({:escalation_updated, escalation}, socket) do
    send_update(MemberComponent,
      id: "member-escalations",
      current_scope: socket.assigns.current_scope,
      escalation_updated: escalation
    )

    {:noreply, socket}
  end
end
