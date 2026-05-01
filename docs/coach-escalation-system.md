# Human Coach Escalation System

A member-to-coach support channel with SLA tracking, capacity gating, and real-time updates over PubSub. The lifecycle is `pending → in_review → responded → closed`.

## How a member uses it

1. **Reach the page** at `/coach-review` (route in `live_session :authenticated_user_required`).
2. **Submit "Request Coach Review"** — pick a subject and optionally add a note. Three subjects:
   - Plan clarification
   - Motivation support
   - Event prioritization
3. **Submission calls** `Escalations.create_escalation(scope, attrs)`. This:
   - Stamps `user_id` and an `sla_deadline` 48 **business hours** out (weekdays only).
   - Refuses with `{:error, :at_capacity}` if the Command Centre's active-client cap (default 50) is reached AND the member doesn't already have an open escalation. Existing active clients can always file more.
   - Notifies coaches and the member by email and broadcasts on PubSub.
4. **Watch status update live** in the same page — the member's escalation row reflects `Pending → In review → Responded → Closed` without a refresh, because the LiveView subscribes to `escalations:user:<id>` and forwards `{:escalation_updated, _}` into `MemberComponent`.

## How a coach uses it

1. **Coach dashboard** at `/coach/escalations` (gated by the `:coach` or `:admin` role plug + `ensure_coach_or_admin` on_mount).
2. **Pending queue** is ordered by SLA urgency, with metrics on top. The view subscribes to `escalations:pending` so newly-filed items appear immediately and items others claim disappear immediately.
3. **Claim** an escalation → `Escalations.assign_coach/2` sets `coach_id` and flips status to `:in_review` (removing it from the queue).
4. **Open it** at `/coach/escalations/:id` — shows the member's profile snippet, plan context, the chat-message context (if any), the user note, and pillar labels.
5. **Respond** — `submit_response` writes `coach_response`, sets `responded_at`, and transitions to `:responded`. The member's page lights up in real time.
6. **Close** — `close_changeset/1` moves status to `:closed`, freeing capacity.

## Key invariants

- **SLA**: 48 business hours from creation, weekends skipped.
- **Capacity gate**: Counts distinct users with non-closed escalations against `:escalation_capacity_cap`.
- **Real-time**: Two PubSub topics — per-user (`escalations:user:<id>`) for the member view, global (`escalations:pending`) for the coach queue.
- **Authorization**: Member route under the standard authenticated pipeline; coach routes pipe through `:require_coach_or_admin`.

## Schema

`SheCommands.Escalations.Escalation` (`escalations` table):

| Field | Type | Notes |
|---|---|---|
| `user_id` | belongs_to User | the member |
| `coach_id` | belongs_to User | set on claim |
| `plan_id` | belongs_to Plan | optional context |
| `chat_message_id` | belongs_to ChatMessage | optional context |
| `subject` | enum | `:plan_clarification`, `:motivation_support`, `:event_prioritization` |
| `status` | enum | `:pending`, `:in_review`, `:responded`, `:closed` |
| `user_note` | string | member's note |
| `coach_response` | string | coach's reply |
| `sla_deadline` | utc_datetime | computed at creation, business-hours aware |
| `responded_at` | utc_datetime | stamped on respond |

## Code map

- Context: `lib/she_commands/escalations.ex`
- Schema: `lib/she_commands/escalations/escalation.ex`
- Member LiveView: `lib/she_commands_web/live/escalation_live/member_index.ex` + `member_component.ex`
- Coach queue: `lib/she_commands_web/live/coach_live/escalation_index.ex`
- Coach detail: `lib/she_commands_web/live/coach_live/escalation_show.ex`
- Routes: `lib/she_commands_web/router.ex` (`/coach-review`, `/coach/escalations`, `/coach/escalations/:id`)
