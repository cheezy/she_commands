defmodule SheCommandsWeb.EscalationLive.MemberComponent do
  @moduledoc """
  LiveComponent for the member-facing escalation flag form and status panel.

  Renders a "Request Coach Review" form (subject + optional note) and a
  list of the member's escalations with their current status. Subscribes
  to PubSub for real-time updates so coach actions appear without a
  manual refresh.

  Required assigns:
    - :id (string, the LiveComponent id)
    - :current_scope (SheCommands.Accounts.Scope)
  """

  use SheCommandsWeb, :live_component

  alias SheCommands.Accounts.Scope
  alias SheCommands.Escalations
  alias SheCommands.Escalations.Escalation

  @impl true
  def update(%{escalation_updated: _escalation} = assigns, socket) do
    {:ok, assign_escalations(socket, assigns.current_scope)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:flash_message, fn -> nil end)
      |> assign_escalations(assigns.current_scope)

    {:ok, socket}
  end

  defp assign_escalations(socket, %Scope{user: user}) do
    escalations =
      user
      |> Scope.for_user()
      |> Escalations.list_escalations_for_user()

    assign(socket, :escalations, escalations)
  end

  @impl true
  def handle_event(
        "submit_escalation",
        %{"subject" => subject_str} = params,
        socket
      ) do
    subject =
      if subject_str in subject_strings(),
        do: String.to_existing_atom(subject_str),
        else: nil

    note = Map.get(params, "user_note", "")

    case Escalations.create_escalation(socket.assigns.current_scope, %{
           subject: subject,
           user_note: note
         }) do
      {:ok, _escalation} ->
        {:noreply,
         socket
         |> assign(:flash_message, gettext("Your request has been sent to a coach."))
         |> assign_escalations(socket.assigns.current_scope)}

      {:error, _changeset} ->
        {:noreply,
         assign(
           socket,
           :flash_message,
           gettext("Please choose a subject before submitting.")
         )}
    end
  end

  defp subject_strings do
    Enum.map(Escalation.subjects(), &Atom.to_string/1)
  end

  def subject_label(:plan_clarification), do: gettext("Plan clarification")
  def subject_label(:motivation_support), do: gettext("Motivation support")
  def subject_label(:event_prioritization), do: gettext("Event prioritization")

  def status_label(:pending), do: gettext("Pending")
  def status_label(:in_review), do: gettext("In review")
  def status_label(:responded), do: gettext("Responded")
  def status_label(:closed), do: gettext("Closed")
end
