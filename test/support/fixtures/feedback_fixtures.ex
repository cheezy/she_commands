defmodule SheCommands.FeedbackFixtures do
  @moduledoc """
  Test helpers for creating Feedback entities.
  """

  import SheCommands.AccountsFixtures, only: [user_fixture: 1]
  import SheCommands.PlansFixtures

  alias SheCommands.Feedback

  def feedback_prompt_fixture(attrs \\ %{}) do
    {user, attrs} = Map.pop_lazy(attrs, :user, fn -> user_fixture(%{}) end)
    {plan, attrs} = Map.pop_lazy(attrs, :plan, fn -> plan_fixture(%{user: user}) end)

    attrs =
      Enum.into(attrs, %{
        plan_id: plan.id,
        user_id: user.id,
        prompt_type: :mid_plan
      })

    {:ok, prompt} = Feedback.create_feedback_prompt(attrs)
    prompt
  end

  def feedback_survey_fixture(attrs \\ %{}) do
    {user, attrs} = Map.pop_lazy(attrs, :user, fn -> user_fixture(%{}) end)
    {plan, attrs} = Map.pop_lazy(attrs, :plan, fn -> plan_fixture(%{user: user}) end)

    attrs =
      Enum.into(attrs, %{
        plan_id: plan.id,
        user_id: user.id,
        survey_type: :mid_plan_check
      })

    {:ok, survey} = Feedback.create_feedback_survey(attrs)
    survey
  end
end
