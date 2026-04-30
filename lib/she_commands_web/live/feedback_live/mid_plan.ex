defmodule SheCommandsWeb.FeedbackLive.MidPlan do
  @moduledoc """
  LiveView for the mid-plan check-in. Members land here from the email
  link in `/feedback/prompts/:id`.

  Authorization: only the user the prompt belongs to can view or
  respond. Already-responded prompts render a thank-you panel with the
  prior answer.
  """

  use SheCommandsWeb, :live_view

  alias SheCommands.Feedback

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    prompt = Feedback.get_feedback_prompt!(id)
    user = socket.assigns.current_scope.user

    if prompt.user_id == user.id do
      {:ok,
       socket
       |> assign(:page_title, gettext("Mid-plan check-in"))
       |> assign(:prompt, prompt)
       |> assign(:selected, nil)
       |> assign(:comment, "")}
    else
      {:ok,
       socket
       |> put_flash(:error, gettext("That feedback prompt is not yours."))
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("submit", %{"answer" => answer} = params, socket) do
    comment = Map.get(params, "comment", "") |> String.trim()

    cond do
      answer not in ["yes", "no", "somewhat"] ->
        {:noreply, put_flash(socket, :error, gettext("Please choose Yes, No, or Somewhat."))}

      socket.assigns.prompt.status == :responded ->
        {:noreply, socket}

      true ->
        response =
          case comment do
            "" -> humanize_answer(answer)
            _ -> humanize_answer(answer) <> " — " <> comment
          end

        {:ok, updated} = Feedback.mark_prompt_responded(socket.assigns.prompt, response)

        {:noreply,
         socket
         |> assign(:prompt, updated)
         |> put_flash(:info, gettext("Thanks for the check-in."))}
    end
  end

  def humanize_answer("yes"), do: "Yes"
  def humanize_answer("no"), do: "No"
  def humanize_answer("somewhat"), do: "Somewhat"
end
