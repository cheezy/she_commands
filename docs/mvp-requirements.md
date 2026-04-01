# She Commands — Command Centre MVP Requirements

## Overview

The Command Centre is a personalized goal execution platform that generates custom multi-disciplinary plans for women based on their specific goal, timeline, and constraints. It integrates four domains — fitness, nutrition, mindset, and leadership/presence — into a single weekly execution plan, supported by AI coaching and a goal-based community.

---

## 1. User Accounts & Access

Users need to sign up, log in, and have role-based access.

- **Members** — the women using the platform
- **Coaches** — Paula, Andrea, Jenna + future facilitators (view escalations, moderate cohorts)
- **Admin** — Myra and team (manage modules, view analytics, manage cohorts)

**Open decision:** How does signup work? The original docs mention Squarespace integration for payment. Are we handling payment/subscription in the Phoenix app or keeping that on Squarespace and doing an auth handoff?

---

## 2. Conversational Intake

Noom-style onboarding — one question per screen, progress bar, reinforcement messages. This is the first real experience.

- ~12 intake fields:
  - Goal intent (free text + dropdown)
  - Goal category (single select: Commanding Presence, Decision-Making & Taking Action, Stress & Anxiety, Emotional Resilience, Physical Vitality — more added over time)
  - Lead time to goal (single select: ≤2 weeks / 3–6 weeks / 7+ weeks)
  - Days per week available (number selector, 1–7)
  - Hours per day available (single select: <30 min / 30–60 min / 60+ min)
  - Intensity preference (single select: Low / Moderate / High)
  - Limitations and preferences (multi-select + free text: menopause, injuries, dietary restrictions, etc.)
  - Coaching preference (single select: Self-directed / Coach-guided)
  - Current fitness regimen (single select + free text: None / Light / Moderate / Active)
  - Current personal development regimen (single select + free text: None / Some / Active)
  - City / Province / Country (text / dropdown)
  - Feedback interest (toggle: Yes / No)
- Mix of input types: free text, single select, multi-select, number selector, toggle
- Contextual "why we're asking" copy per question
- Positive reinforcement at milestones (e.g., "That's a meaningful goal — here's how we'll approach it")
- Completion triggers plan generation automatically
- Intake responses stored and editable (for plan renewal/restart)

**Open decision:** Do we want the free-text goal intent to auto-suggest a goal category via AI, or keep it as manual selection for now?

---

## 3. Module Library (The Data Engine)

The heart of the system. Everything flows from it.

- Import from existing structured spreadsheet
- Full tagging schema per module:
  - Module ID, Contributor name, Title, Overview, Core Concepts
  - Power Pillar (1–2 per module): Power Up, Power Through, Power Down, Empower
  - Goal Category (1–2 per module)
  - Outcomes
  - Protocols (up to 4 per module with steps and prescriptions)
  - Modifications
  - Coach Tip (attributed to named expert: Paula V / Andrea F / Jenna M)
  - Sources
  - Intensity Level (Low / Moderate / High)
  - Time Requirement (15 / 30 / 45 / 60 minutes)
  - Protocol Frequency (1x–5x per week)
  - Lead Time Fit (Short / Medium / Long)
  - Complementary Module IDs
  - Module Type (Foundational / Secondary / Assisted / Bespoke)
  - Reward Eligible (yes/no)
  - Video Available (yes/no)
  - Outcome Keywords (e.g., Clarity, Confidence, Strength, Calm)
- Must be queryable by all fields
- Extensible — new goal categories and modules added over time without code changes

**Open decision:** Do we need an admin UI for module management at MVP, or is seeding from spreadsheet + console access sufficient to start?

---

## 4. Logic Engine (Plan Generation)

Rule-based, architected for AI evolution.

### Rules

- **Goal category → module pool:** each goal category has a pre-tagged set of modules; system selects from modules tagged to the user's selected goal category
- **Lead time → plan type:**
  - ≤2 weeks → Weekly Plan (1–2 core protocols per pillar)
  - 3–6 weeks → Bi-Weekly Plan (progression-based protocols)
  - ≥7 weeks → Monthly Plan (full progressions + complementary add-ons)
  - **Critical rule:** system does not generate monthly plans for lead time under 3 weeks
- **Intensity + availability → protocol filtering:**
  - Available hours/day filters out protocols exceeding session length
  - Days/week caps protocol frequency (≤3 days/week = 1 module per pillar)
  - Intensity level maps to protocol intensity tags in module library
- **Power Pillar coverage (non-negotiable):** minimum 1 protocol per Power Pillar in every plan
  - If time constraints prevent this, system flags and asks user to adjust availability inputs
- **Complementary module inclusion:** if a selected module has complementary tags AND user has >3 days/week AND <5 modules already selected → auto-include
- **Coach tips:** pulled from each selected module, attributed to named expert
- **Expected outcomes:** pulled from goal category presets

### Output

- Structured execution plan ready for rendering

**Open decision:** If the user's time constraints prevent covering all 4 pillars, should this be a hard block or a best-effort plan with a warning?

---

## 5. Execution Plan (The Value Delivery)

The thing the user opens on Monday morning.

### Required Components

1. Goal statement — personalized from intake free text + goal category language
2. Expected outcomes — pulled from goal category presets
3. Power Pillar overview — which pillars are prioritized and why for this goal
4. Selected modules and protocols — with full protocol steps and prescriptions
5. Named coach tips — attributed to contributor per selected module
6. Time-based weekly schedule — day-by-day layout matching user's available days and hours
7. Modifications — relevant modifications from selected modules (e.g., seated alternatives, menopausal adaptations)

### Delivery

- Mobile-responsive in-app view (primary use case: phone on a Monday morning)
- PDF export (user-initiated)
- Clean, branded layout

**Open decision:** Plan versioning — if a user retakes intake or modifies goals mid-plan, do we archive the old plan and generate fresh, or allow incremental edits?

---

## 6. AI Chatbot (Always-On Support)

Embedded in the plan view, scoped to the user's context.

- Answers questions about the plan: what a protocol means, how to modify it, when to do it
- Answers general questions about Power Pillars, goal categories, programme principles
- Draws from module content, protocol descriptions, and goal category definitions
- Brand voice: direct, warm, non-clinical (aligned to She Commands brand)
- Does NOT provide personalized medical, nutritional, or fitness advice
- Does NOT have access to other users' data
- RAG layer over the user's plan + module content + goal category definitions

**Open decision:** Claude API as the LLM backend?

---

## 7. Human Coach Escalation

Async support when the chatbot isn't enough.

- User flags a chatbot conversation for human coach review
- Coach dashboard: pending escalations queue, user profile, plan context
- Coach responds asynchronously within 48-hour SLA (weekdays only)
- Coaches do NOT proactively initiate contact (scalability constraint)
- Defined scope communicated at onboarding:
  - Plan clarification and protocol modifications
  - Motivation and accountability support
  - Guidance on prioritization for specific upcoming events
  - NOT: open-ended life coaching, medical/nutritional/fitness advice
- Capacity cap on active Command Centre clients
- Email notification to coaches on new escalations

---

## 8. Feedback Loop

Capture data to validate assumptions and refine plan logic.

- **Mid-plan micro-prompt:** "Was this week doable?" (in-app or email, halfway through plan period)
- **Post-plan survey:** 2–3 questions — "What changed?", "What was hardest?", "What do you want next?" (in-app or email, on plan completion)
- Data feeds back into plan refinement and content development

### Success Metrics to Track

- Onboarding completion rate (target: 50%)
- Weekly module/protocol views (target: 40%)
- Support requests and escalation volume (target: <25% require human escalation)
- Plan completion rate (target: 20%)
- Post-plan survey completion rate

---

## Fast-Follows (Post-MVP)

These are valuable but not required for initial launch:

- **Cohort Community** — Goal-based groups of 8–15 members with assigned coach moderator, weekly prompts, async discussion. Start with external platform (Circle/Geneva), bring in-app later.
- **Command Coins / Gamification** — Milestone rewards, coin balance, progress tracking dashboard, streak tracking.
- **Event Integration Pipeline** — Flag users who complete plans or express interest in deeper support, surface as retreat/event leads.
- **Admin Module Management UI** — Full CRUD interface for modules. Seed from spreadsheet initially.
- **Proactive Coach Check-ins** — Triggered by inactivity (e.g., no protocol logged for 5+ days).
- **Progress Tracking Dashboard** — Protocol completion visualization, streak tracking.
- **Video Library** — Protocol delivery via video.
- **Push Notifications** — Reminders tied to the daily schedule.
- **Exportable Progress Reports & Certificates**

---

## Non-Functional Requirements

- **Mobile-first:** primary use case is opening the plan on a phone
- **Canadian market:** PIPEDA compliance required for health/goal data
- **Branding:** She Commands design system (minimalist black/white, Space Grotesk headlines, Inter body)
- **Extensibility:** architecture must support new goal categories, modules, and disciplines without code changes
- **Integration:** seamless handoff from shecommands.ca (Squarespace) for signup and payment

---

## Key Differentiators (Must Be Preserved)

1. **Named expert credibility layer** — every plan surfaces the contributing expert's name and credential alongside their protocol and coaching tip
2. **Proprietary Power Pillar framework** — the four-pillar structure must be visually and structurally present throughout the app experience
3. **Goal category roadmap architecture** — extensible goal categories and module tagging without rebuilding the logic engine
4. **Live event integration pipeline** — Command Centre clients as a warm pipeline for She Commands retreats and live experiences
