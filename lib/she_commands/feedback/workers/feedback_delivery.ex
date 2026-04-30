defmodule SheCommands.Feedback.Workers.FeedbackDelivery do
  @moduledoc """
  Oban worker that delivers a feedback prompt by email and transitions
  the prompt to `:sent`.

  Idempotent: prompts already in `:sent`, `:responded`, or `:expired`
  are short-circuited as `:ok`. Email transport failures bubble up so
  Oban retries the job per `max_attempts`.
  """

  use Oban.Worker, queue: :feedback, max_attempts: 5

  alias SheCommands.Accounts
  alias SheCommands.Accounts.UserNotifier
  alias SheCommands.Feedback

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"prompt_id" => prompt_id}}) do
    prompt = Feedback.get_feedback_prompt!(prompt_id)

    case prompt.status do
      :pending ->
        deliver(prompt)

      _other ->
        :ok
    end
  end

  defp deliver(prompt) do
    member = Accounts.get_user!(prompt.user_id)

    case UserNotifier.deliver_feedback_prompt_email(member, prompt) do
      {:ok, _email} ->
        {:ok, _updated} = Feedback.mark_prompt_sent(prompt)
        :ok

      {:error, reason} ->
        # Surface to Oban for retry
        {:error, reason}
    end
  end
end
