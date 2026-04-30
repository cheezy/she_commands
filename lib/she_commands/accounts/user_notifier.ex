defmodule SheCommands.Accounts.UserNotifier do
  import Swoosh.Email

  alias SheCommands.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"SheCommands", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Notifies a coach that a new escalation needs review.

  `escalation` must have `:user` preloaded so the member's display name
  can be rendered. `dashboard_url` is the absolute link to the coach
  queue.
  """
  def deliver_new_escalation_notification(coach, escalation, dashboard_url) do
    member_name = member_display_name(escalation.user)
    subject_line = humanize_subject(escalation.subject)

    deliver(coach.email, "New escalation: #{subject_line}", """

    ==============================

    Hi #{coach.email},

    A new escalation is waiting for coach review.

    Member: #{member_name}
    Subject: #{subject_line}

    Open the queue: #{dashboard_url}

    ==============================
    """)
  end

  @doc """
  Confirms receipt of an escalation to the member who submitted it.
  Includes the SLA timeline and the scope of coach support.
  """
  def deliver_escalation_confirmation(member, escalation) do
    subject_line = humanize_subject(escalation.subject)

    deliver(member.email, "We received your coach review request", """

    ==============================

    Hi #{member.email},

    We received your request for coach review on "#{subject_line}".

    A coach will respond within 48 business hours (weekends excluded).

    Coach support covers plan clarification, motivation, and event
    prioritization. For medical, nutritional, or fitness questions,
    please consult a qualified professional.

    ==============================
    """)
  end

  defp member_display_name(nil), do: "a member"

  defp member_display_name(user) do
    cond do
      user.display_name && user.display_name != "" -> user.display_name
      user.name && user.name != "" -> user.name
      true -> "a member"
    end
  end

  @doc """
  Notifies a member that their coach has replied. Includes the coach
  response excerpt and a link to view the full response.
  """
  def deliver_coach_response_notification(member, escalation) do
    subject_line = humanize_subject(escalation.subject)
    response = escalation.coach_response || ""
    link = view_url(escalation)

    deliver(member.email, "Your coach has responded: #{subject_line}", """

    ==============================

    Hi #{member.email},

    Your coach has responded to your "#{subject_line}" request.

    #{response}

    View the full response: #{link}

    ==============================
    """)
  end

  defp view_url(_escalation) do
    SheCommandsWeb.Endpoint.url() <> "/coach-review"
  end

  defp humanize_subject(:plan_clarification), do: "Plan clarification"
  defp humanize_subject(:motivation_support), do: "Motivation support"
  defp humanize_subject(:event_prioritization), do: "Event prioritization"
  defp humanize_subject(other), do: other |> Atom.to_string() |> String.replace("_", " ")
end
