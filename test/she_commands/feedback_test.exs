defmodule SheCommands.FeedbackTest do
  use SheCommands.DataCase, async: true

  import SheCommands.AccountsFixtures
  import SheCommands.FeedbackFixtures
  import SheCommands.PlansFixtures

  alias SheCommands.Feedback
  alias SheCommands.Feedback.FeedbackPrompt
  alias SheCommands.Feedback.FeedbackSurvey

  describe "create_feedback_prompt/1" do
    test "creates a pending prompt with valid attrs" do
      user = user_fixture(%{})
      plan = plan_fixture(%{user: user})

      assert {:ok, %FeedbackPrompt{} = prompt} =
               Feedback.create_feedback_prompt(%{
                 plan_id: plan.id,
                 user_id: user.id,
                 prompt_type: :mid_plan
               })

      assert prompt.status == :pending
      assert prompt.prompt_type == :mid_plan
    end

    test "rejects missing required fields" do
      assert {:error, changeset} = Feedback.create_feedback_prompt(%{})
      errors = errors_on(changeset)
      assert errors[:plan_id] != []
      assert errors[:user_id] != []
      assert errors[:prompt_type] != []
    end

    test "rejects unknown prompt_type" do
      user = user_fixture(%{})
      plan = plan_fixture(%{user: user})

      assert {:error, changeset} =
               Feedback.create_feedback_prompt(%{
                 plan_id: plan.id,
                 user_id: user.id,
                 prompt_type: :bogus
               })

      assert errors_on(changeset).prompt_type != []
    end

    test "returns error when plan_id does not exist" do
      user = user_fixture(%{})

      assert {:error, changeset} =
               Feedback.create_feedback_prompt(%{
                 plan_id: -1,
                 user_id: user.id,
                 prompt_type: :mid_plan
               })

      assert errors_on(changeset).plan_id != []
    end

    test "two prompts for the same plan are both allowed" do
      user = user_fixture(%{})
      plan = plan_fixture(%{user: user})

      base = %{plan_id: plan.id, user_id: user.id, prompt_type: :mid_plan}
      assert {:ok, _} = Feedback.create_feedback_prompt(base)
      assert {:ok, _} = Feedback.create_feedback_prompt(%{base | prompt_type: :post_plan})
    end
  end

  describe "list_prompts_for_plan/1" do
    test "returns prompts for the plan ordered by scheduled_for" do
      user = user_fixture(%{})
      plan = plan_fixture(%{user: user})
      other_plan = plan_fixture(%{user: user})

      now = DateTime.utc_now() |> DateTime.truncate(:second)
      first = feedback_prompt_fixture(%{plan: plan, scheduled_for: DateTime.add(now, 60)})
      second = feedback_prompt_fixture(%{plan: plan, scheduled_for: DateTime.add(now, 120)})
      _other = feedback_prompt_fixture(%{plan: other_plan})

      ids = Feedback.list_prompts_for_plan(plan.id) |> Enum.map(& &1.id)
      assert ids == [first.id, second.id]
    end
  end

  describe "list_prompts_for_user/1" do
    test "returns prompts for the user newest first" do
      user = user_fixture(%{})
      other = user_fixture(%{})

      _stranger = feedback_prompt_fixture(%{user: other})
      mine_first = feedback_prompt_fixture(%{user: user})
      mine_second = feedback_prompt_fixture(%{user: user})

      ids = Feedback.list_prompts_for_user(user.id) |> Enum.map(& &1.id)
      assert ids == [mine_second.id, mine_first.id]
    end
  end

  describe "get_pending_prompts/0" do
    test "returns only pending prompts whose scheduled_for is past or unset" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      past = DateTime.add(now, -3600)
      future = DateTime.add(now, 3600)

      due = feedback_prompt_fixture(%{scheduled_for: past})
      _not_due = feedback_prompt_fixture(%{scheduled_for: future})
      unscheduled = feedback_prompt_fixture(%{})

      sent = feedback_prompt_fixture(%{scheduled_for: past})
      {:ok, _} = Feedback.mark_prompt_sent(sent)

      ids = Feedback.get_pending_prompts() |> Enum.map(& &1.id)
      assert due.id in ids
      assert unscheduled.id in ids
      refute sent.id in ids
    end
  end

  describe "mark_prompt_sent/1" do
    test "transitions to :sent and stamps sent_at" do
      prompt = feedback_prompt_fixture()
      assert {:ok, sent} = Feedback.mark_prompt_sent(prompt)
      assert sent.status == :sent
      assert sent.sent_at
    end
  end

  describe "mark_prompt_responded/2" do
    test "stores response and transitions to :responded" do
      prompt = feedback_prompt_fixture()
      assert {:ok, responded} = Feedback.mark_prompt_responded(prompt, "All good")
      assert responded.status == :responded
      assert responded.response == "All good"
      assert responded.responded_at
    end

    test "rejects empty response" do
      prompt = feedback_prompt_fixture()
      assert {:error, changeset} = Feedback.mark_prompt_responded(prompt, nil)
      assert errors_on(changeset).response != []
    end
  end

  describe "mark_prompt_expired/1" do
    test "transitions to :expired" do
      prompt = feedback_prompt_fixture()
      assert {:ok, expired} = Feedback.mark_prompt_expired(prompt)
      assert expired.status == :expired
    end
  end

  describe "create_feedback_survey/1" do
    test "creates a survey with valid attrs" do
      user = user_fixture(%{})
      plan = plan_fixture(%{user: user})

      assert {:ok, %FeedbackSurvey{} = survey} =
               Feedback.create_feedback_survey(%{
                 plan_id: plan.id,
                 user_id: user.id,
                 survey_type: :post_plan_review
               })

      assert survey.survey_type == :post_plan_review
      assert survey.responses == %{}
    end

    test "rejects missing required fields" do
      assert {:error, changeset} = Feedback.create_feedback_survey(%{})
      assert errors_on(changeset).plan_id != []
      assert errors_on(changeset).user_id != []
      assert errors_on(changeset).survey_type != []
    end
  end

  describe "complete_survey/2" do
    test "stores responses and stamps completed_at" do
      survey = feedback_survey_fixture()

      assert {:ok, completed} =
               Feedback.complete_survey(survey, %{"q1" => "yes", "q2" => "5"})

      assert completed.responses == %{"q1" => "yes", "q2" => "5"}
      assert completed.completed_at
    end

    test "accepts an empty response map" do
      survey = feedback_survey_fixture()
      assert {:ok, completed} = Feedback.complete_survey(survey, %{})
      assert completed.responses == %{}
      assert completed.completed_at
    end
  end

  describe "list_surveys_for_user/1" do
    test "returns only that user's surveys" do
      user = user_fixture(%{})
      other = user_fixture(%{})

      _theirs = feedback_survey_fixture(%{user: other})
      mine = feedback_survey_fixture(%{user: user})

      ids = Feedback.list_surveys_for_user(user.id) |> Enum.map(& &1.id)
      assert ids == [mine.id]
    end
  end

  describe "list_surveys_for_plan/1" do
    test "returns only surveys for the plan" do
      user = user_fixture(%{})
      plan = plan_fixture(%{user: user})
      other_plan = plan_fixture(%{user: user})

      mine = feedback_survey_fixture(%{plan: plan, survey_type: :mid_plan_check})
      _other = feedback_survey_fixture(%{plan: other_plan})

      ids = Feedback.list_surveys_for_plan(plan.id) |> Enum.map(& &1.id)
      assert ids == [mine.id]
    end
  end

  describe "survey_completion_rate/0" do
    test "returns 0.0 when no surveys exist" do
      assert Feedback.survey_completion_rate() == 0.0
    end

    test "is the share of surveys with completed_at set" do
      user = user_fixture(%{})

      done = feedback_survey_fixture(%{user: user})
      _open = feedback_survey_fixture(%{user: user})
      _open2 = feedback_survey_fixture(%{user: user})
      {:ok, _} = Feedback.complete_survey(done, %{"q" => "answer"})

      assert_in_delta Feedback.survey_completion_rate(), 1 / 3, 0.001
    end
  end

  describe "get_feedback_prompt!/1 and get_feedback_survey!/1" do
    test "fetch existing rows" do
      prompt = feedback_prompt_fixture()
      survey = feedback_survey_fixture()
      assert Feedback.get_feedback_prompt!(prompt.id).id == prompt.id
      assert Feedback.get_feedback_survey!(survey.id).id == survey.id
    end

    test "raise when not found" do
      assert_raise Ecto.NoResultsError, fn -> Feedback.get_feedback_prompt!(-1) end
      assert_raise Ecto.NoResultsError, fn -> Feedback.get_feedback_survey!(-1) end
    end
  end
end
