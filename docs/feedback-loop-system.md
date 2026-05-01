# Feedback Loop System

A two-touch feedback loop tied to each plan: a **mid-plan check-in** ("was this week doable?") and a **post-plan review** (three open-ended questions). Both are scheduled automatically as a side effect of plan status transitions, delivered by email with a link back into the app, and answered in a LiveView form.

## Lifecycle at a glance

```
Plan goes :active   ─▶ FeedbackScheduler ─▶ FeedbackPrompt(:mid_plan, scheduled_for: +N days)
                                              │
                                              └─▶ FeedbackDelivery (Oban scheduled_at)
                                                     │  sends email + marks :sent
                                                     ▼
                                              member clicks link → /feedback/prompts/:id
                                                     │
                                                     ▼
                                              :responded (with answer + optional comment)

Plan goes :completed ─▶ PlanCompletionSurvey ─▶ FeedbackSurvey(:post_plan_review)
                                                     │
                                              email link → /feedback/surveys/:id
                                                     │
                                                     ▼
                                              :completed_at stamped (responses stored as map)
```

There are two distinct shapes — a `FeedbackPrompt` (single-question check-in) and a `FeedbackSurvey` (multi-question review). They share the same goal of closing the feedback loop but they are different schemas, different workers, and different routes.

## Mid-plan check-in (`FeedbackPrompt`)

### Trigger

When a plan transitions to `:active`, `Plans.update_plan/2` enqueues a `FeedbackScheduler` Oban job. That job:

1. **Skips** if the plan already has a `:mid_plan` prompt (idempotent).
2. Computes a delivery offset based on `plan.plan_type`:
   - `:weekly` → day 4 of 7
   - `:biweekly` → day 8 of 14
   - `:monthly` → day 15 of 30
3. Inserts a `FeedbackPrompt` (status `:pending`, `scheduled_for` = offset).
4. Enqueues `FeedbackDelivery` with `scheduled_at: scheduled_for`.

### Delivery

When the scheduled time arrives, `FeedbackDelivery`:

- Fetches the prompt; if it's no longer `:pending` (already sent / responded / expired), returns `:ok` and does nothing.
- Otherwise calls `UserNotifier.deliver_feedback_prompt_email/2`. The email subject is **"Was this week doable?"** with a link to `/feedback/prompts/:id`.
- On success: transitions the prompt to `:sent` and stamps `sent_at`.
- On transport failure: returns `{:error, _}` so Oban retries up to `max_attempts: 5`.

### How a member accesses and uses it

1. **Email arrives** with the subject "Was this week doable?" and a link.
2. Click the link → land on `/feedback/prompts/:id` (`SheCommandsWeb.FeedbackLive.MidPlan`). Authentication required; the LiveView refuses to render unless `prompt.user_id == current_scope.user.id` (otherwise: flash + redirect to `/`).
3. **Choose** Yes / No / Somewhat.
4. **Optionally add a comment** in the free-text field.
5. **Submit** — the LiveView builds a single string response (e.g., `"Somewhat — the weekend got away from me"`) and calls `Feedback.mark_prompt_responded/2`, which:
   - Stores the answer in `response`
   - Stamps `responded_at`
   - Transitions status to `:responded`
6. The page flashes "Thanks for the check-in." Re-visiting the link shows the prior answer in a thank-you panel — the form is locked because `prompt.status == :responded` short-circuits the submit handler.

### States

`FeedbackPrompt.statuses/0` → `[:pending, :sent, :responded, :expired]`
- `:pending` — created, not yet delivered
- `:sent` — email delivered (waiting on the member)
- `:responded` — member submitted an answer
- `:expired` — member never replied in time (`mark_prompt_expired/1`)

## Post-plan review (`FeedbackSurvey`)

### Trigger

When a plan transitions to `:completed`, `Plans.update_plan/2` enqueues a `PlanCompletionSurvey` Oban job. That worker:

1. **Skips** if the plan already has a `:post_plan_review` survey (idempotent).
2. Inserts a `FeedbackSurvey` row (`survey_type: :post_plan_review`, no `completed_at` yet).

The survey email is delivered via `UserNotifier.deliver_post_plan_survey/2` (subject **"How did your plan go?"**) with a link to `/feedback/surveys/:id`.

### How a member accesses and uses it

1. **Email arrives** at plan completion with three questions and a link.
2. Click → land on `/feedback/surveys/:id` (`SheCommandsWeb.FeedbackLive.PostPlan`). Authentication required; `survey.user_id == current_scope.user.id` enforced (otherwise: flash + redirect).
3. **Answer three open-ended questions**:
   - "What changed?"
   - "What was hardest?"
   - "What do you want next?"
4. **Submit** — the LiveView trims and stores the responses as a map and calls `Feedback.complete_survey/2`, which:
   - Stores the map in `responses` (free-form `:map` field, no migration needed to evolve question wording)
   - Stamps `completed_at`
5. The page flashes "Thanks for the feedback." Re-visiting after completion renders a read-only summary; submitting again is short-circuited because `survey.completed_at != nil`.

### Validation
- At least one of the three answers must be non-blank — submitting all-blank flashes "Please answer at least one question."

## Aggregate metric

`Feedback.survey_completion_rate/0` returns the post-plan-survey completion rate as a `0.0..1.0` float (0.0 when there are zero surveys, no division-by-zero). This is the seed metric for an admin metrics dashboard.

## Schema

### `feedback_prompts` (`SheCommands.Feedback.FeedbackPrompt`)

| Field | Type | Notes |
|---|---|---|
| `plan_id` | belongs_to Plan | scope |
| `user_id` | belongs_to User | recipient |
| `prompt_type` | enum | `:mid_plan` or `:post_plan` |
| `status` | enum | `:pending`, `:sent`, `:responded`, `:expired` |
| `scheduled_for` | utc_datetime | when delivery worker should fire |
| `sent_at` | utc_datetime | stamped on email send |
| `responded_at` | utc_datetime | stamped on submit |
| `response` | string | one humanized answer + optional note |
| timestamps | utc_datetime | |

### `feedback_surveys` (`SheCommands.Feedback.FeedbackSurvey`)

| Field | Type | Notes |
|---|---|---|
| `plan_id` | belongs_to Plan | scope |
| `user_id` | belongs_to User | recipient |
| `survey_type` | enum | `:mid_plan_check`, `:post_plan_review` |
| `responses` | map | free-form answers; survey wording can change without a migration |
| `completed_at` | utc_datetime | nil until submitted |
| timestamps | utc_datetime | |

## Authorization summary

- Both feedback routes live in the authenticated `live_session` and require a logged-in user.
- The LiveView mounts both refuse to render unless the prompt/survey belongs to the current user, redirecting to `/` with an error flash otherwise.
- There is no public "anyone with the link" access — links are personal.

## Idempotency and retries

- `FeedbackScheduler` is idempotent on `(plan_id, :mid_plan)` — re-firing the activation job will not duplicate prompts.
- `FeedbackDelivery` short-circuits anything not `:pending` — `:sent` / `:responded` / `:expired` rows are never re-emailed.
- `PlanCompletionSurvey` is idempotent on `(plan_id, :post_plan_review)`.
- Email transport failures bubble up so Oban retries (`max_attempts` 3–5 depending on worker).

## Code map

- Context: `lib/she_commands/feedback.ex`
- Schemas:
  - `lib/she_commands/feedback/feedback_prompt.ex`
  - `lib/she_commands/feedback/feedback_survey.ex`
- Workers:
  - `lib/she_commands/feedback/workers/feedback_scheduler.ex`
  - `lib/she_commands/feedback/workers/feedback_delivery.ex`
  - `lib/she_commands/feedback/workers/plan_completion_survey.ex`
- LiveViews:
  - `lib/she_commands_web/live/feedback_live/mid_plan.ex`
  - `lib/she_commands_web/live/feedback_live/post_plan.ex`
- Email templates: `lib/she_commands/accounts/user_notifier.ex` (`deliver_mid_plan_prompt/2`, `deliver_post_plan_survey/2`)
- Routes (in `lib/she_commands_web/router.ex`):
  - `/feedback/prompts/:id` → `FeedbackLive.MidPlan`
  - `/feedback/surveys/:id` → `FeedbackLive.PostPlan`
- Trigger: `Plans.update_plan/2` enqueues feedback jobs on `:active` and `:completed` transitions
