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

  @doc """
  Delivers a mid-plan or post-plan feedback prompt to the member.

  Dispatches to `deliver_mid_plan_prompt/2` or `deliver_post_plan_survey/2`
  based on `prompt.prompt_type` so the FeedbackDelivery worker only has
  to know one entry point.
  """
  def deliver_feedback_prompt_email(member, %{prompt_type: :mid_plan} = prompt),
    do: deliver_mid_plan_prompt(member, prompt)

  def deliver_feedback_prompt_email(member, %{prompt_type: :post_plan} = prompt),
    do: deliver_post_plan_survey(member, prompt)

  @doc """
  Delivers the mid-plan check-in prompt: "Was this week doable?" with a
  link back to the in-app feedback form.
  """
  def deliver_mid_plan_prompt(member, prompt) do
    greeting = greeting_name(member)
    link = feedback_prompt_url(prompt)

    deliver(member.email, "Was this week doable?", """

    ==============================

    Hi #{greeting},

    Quick mid-plan check-in: was this week doable?

    Reply directly or share your answer in the app:
    #{link}

    ==============================
    """)
  end

  @doc """
  Delivers the post-plan survey invitation with three review questions
  and a link back to the in-app survey form.
  """
  def deliver_post_plan_survey(member, prompt) do
    greeting = greeting_name(member)
    link = feedback_prompt_url(prompt)

    deliver(member.email, "How did your plan go?", """

    ==============================

    Hi #{greeting},

    Your plan has wrapped — three quick questions to close the loop:

    1. What worked best for you?
    2. What got in the way?
    3. What would you change for the next plan?

    Share your answers in the app:
    #{link}

    ==============================
    """)
  end

  defp greeting_name(%{display_name: dn}) when is_binary(dn) and dn != "", do: dn
  defp greeting_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp greeting_name(%{email: email}) when is_binary(email), do: email
  defp greeting_name(_), do: "there"

  defp feedback_prompt_url(prompt) do
    SheCommandsWeb.Endpoint.url() <> "/feedback/prompts/#{prompt.id}"
  end

  defp humanize_subject(:plan_clarification), do: "Plan clarification"
  defp humanize_subject(:motivation_support), do: "Motivation support"
  defp humanize_subject(:event_prioritization), do: "Event prioritization"
  defp humanize_subject(other), do: other |> Atom.to_string() |> String.replace("_", " ")
end
