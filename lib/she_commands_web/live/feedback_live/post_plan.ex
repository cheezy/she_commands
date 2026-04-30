defmodule SheCommandsWeb.FeedbackLive.PostPlan do
  @moduledoc """
  LiveView for the post-plan survey. Members land here from the
  closing-plan email link at `/feedback/surveys/:id`.

  Authorization: only the survey's user can view or submit. Completed
  surveys render a read-only summary of the responses.
  """

  use SheCommandsWeb, :live_view

  alias SheCommands.Feedback

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    survey = Feedback.get_feedback_survey!(id)
    user = socket.assigns.current_scope.user

    if survey.user_id == user.id do
      {:ok,
       socket
       |> assign(:page_title, gettext("Post-plan survey"))
       |> assign(:survey, survey)}
    else
      {:ok,
       socket
       |> put_flash(:error, gettext("That survey is not yours."))
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("submit", params, socket) do
    responses = %{
      "what_changed" => trim(params["what_changed"]),
      "what_was_hardest" => trim(params["what_was_hardest"]),
      "what_do_you_want_next" => trim(params["what_do_you_want_next"])
    }

    all_blank? = responses |> Map.values() |> Enum.all?(&(&1 == ""))

    cond do
      socket.assigns.survey.completed_at != nil ->
        {:noreply, socket}

      all_blank? ->
        {:noreply, put_flash(socket, :error, gettext("Please answer at least one question."))}

      true ->
        {:ok, updated} = Feedback.complete_survey(socket.assigns.survey, responses)

        {:noreply,
         socket
         |> assign(:survey, updated)
         |> put_flash(:info, gettext("Thanks for the feedback."))}
    end
  end

  defp trim(nil), do: ""
  defp trim(value) when is_binary(value), do: String.trim(value)
end
