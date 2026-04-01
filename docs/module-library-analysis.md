# Module Library Analysis & Gap Fill Suggestions

> Based on: `She_Commands_Module_Library_FULL_ALL (2).xlsx`
> Analysis date: 2026-04-01

---

## Current State Summary

| Metric | Count |
|---|---|
| Total modules | 25 |
| Complete (15+ fields filled) | 5 |
| Partial (5-14 fields) | 13 |
| Stubs (<5 fields) | 7 |
| WIP / no Module ID | 11 |

### By Contributor

| Contributor | Modules | Status |
|---|---|---|
| Paula V | 8 | Mostly complete — protocols, coach tips, modifications all filled |
| Andrea F | 3 | Complete — includes TimetoResult, Experience Level, Intensity, DailyTime |
| Jenna M | 3 | Mostly complete — protocols and coach tips filled, some metadata missing |
| Myra | 10 | Mostly WIP — titles and some core concepts, few protocols |
| TBD | 1 | Stub only (Build your personal brand) |

### Field Fill Rates

| Field | Filled | Notes |
|---|---|---|
| Contributor | 25/25 | Complete |
| Title | 25/25 | Complete |
| CoreConcepts | 18/25 | Good |
| GoalCategory1/2 | 18/25 | Good |
| PowerPillar1/2 | 14/25 | 11 modules missing pillar assignments |
| Overview | 16/25 | 9 missing |
| Outcomes | 18/25 | Good |
| Protocol1 (Anchor) | 14/25 | 11 missing |
| Protocol2 | 14/25 | 11 missing |
| Protocol3 | 14/25 | 11 missing |
| Protocol4 | 2/25 | Only Jenna's modules have 4 protocols |
| Modifications | 12/25 | 13 missing |
| Coach Tip | 14/25 | 11 missing |
| **Module Type** | **0/25** | **Completely empty** |
| **ProtocolSequencing** | **0/25** | **Completely empty** |
| **WeeklyFreq** | **0/25** | **Completely empty** |
| **DailyFreq** | **0/25** | **Completely empty** |
| **Video** | **0/25** | **Completely empty** |
| TimetoResult | 3/25 | Only Andrea's modules |
| Experience Level | 3/25 | Only Andrea's modules |
| Intensity | 3/25 | Only Andrea's modules |
| DailyTime | 3/25 | Only Andrea's modules |
| Sources | 2/25 | Only Jenna's modules |
| ModuleID | 11/25 | 11 marked WIP, 3 have no ID at all |

### Goal Categories in Modules vs. Goal Categories Sheet

The Goal Categories sheet defines 15 categories. Modules currently reference 11.

| Goal Category | In Modules? | Module Count |
|---|---|---|
| Commanding Presence | Yes | 3 |
| Critical Thinking | Yes | 3 |
| Decision Making & Taking Action | Yes | 3 |
| Emotional Resilience | Yes | 4 |
| Habit Mastery & Self-Discipline | Yes | 2 |
| Impact & Influence | Yes | 3 |
| Life Force Reclamation | Yes | 1 |
| Physical Vitality (& Strength) | Yes | 4 |
| Stress & Anxiety | Yes | 3 |
| Team Leadership | Yes | 1 |
| Physical Endurance | No | 0 |
| Flexibility & Mobility | No | 0 |
| Personal Relationships | No | 0 |
| Prioritization & Time Mngmt. | No | 0 |
| Relationship Boundaries | No | 0 |

### Power Pillar Coverage

All 4 pillars are represented across existing modules: Power Up, Power Through, Power Down, Empower.

---

## Fields That Need Filling Across All Modules

These fields are critical for the logic engine and are empty or nearly empty everywhere.

### 1. Module Type (0/25 filled)

**What it drives:** The logic engine uses Module Type to determine selection priority (Foundational first, then Secondary to fill pillar gaps). Assisted modules are reserved for live events. Bespoke is TBD.

**Suggested assignments:**

| Module | Suggested Type | Rationale |
|---|---|---|
| Staying Composed in High Pressure Moments (Paula V) | Foundational | Core stress management, broad applicability |
| Command Commitment in the Moment (Paula V) | Foundational | Core decisiveness training |
| Release the Shock (Paula V) | Foundational | Essential emotional regulation |
| Focus on the Positive (Paula V) | Foundational | Core resilience builder |
| Build Capacity for Uncertainty (Paula V) | Foundational | Core decision-making support |
| Command Outcomes When You Don't Own the Room (Paula V) | Secondary | Situational — builds on core influence skills |
| Concentration Power (Paula V) | Foundational | Universal cognitive skill |
| Mental Reset Micro-Breaks (Paula V) | Secondary | Complements focus/endurance modules |
| Better Breakfasts (Andrea F) | Foundational | Entry-level nutrition, broad applicability |
| Anti-Inflammatory Eating (Andrea F) | Secondary | Builds on nutrition foundation |
| Eating for Cognitive Clarity (Andrea F) | Secondary | Specialized nutrition goal |
| Walk with Command - Confidence in Heels (Jenna M) | Secondary | Specialized physical presence |
| Embodying Authority Without Saying a Word (Jenna M) | Foundational | Core presence skill |
| Train with Intention, Perform with Precision (Jenna M) | Foundational | Core physical awareness |
| Communicate with Impact (Myra) | Foundational | Core leadership communication |
| Storytelling to Influence Decisions (Myra) | Secondary | Builds on communication foundation |
| Mobilize a Team (Myra) | Foundational | Core team leadership |
| Cool the Tension and Put People at Ease (Myra) | Secondary | Situational conflict skill |
| Measured Reactions in Unexpected Situations (Myra) | Foundational | Core emotional regulation |
| Make Decisions with Confidence (Myra) | Foundational | Core decision-making |
| Increase Your Gravitational Pull (Myra) | Secondary | Advanced influence |
| Focus on What Matters Most (Myra) | Foundational | Core prioritization |
| Build Your Personal Brand (TBD) | Secondary | Specialized presence/influence |
| Control the Conversation (Myra) | Secondary | Advanced communication |
| Trust Your Interpersonal Instincts (Myra) | Secondary | Advanced emotional intelligence |

### 2. Protocol Sequencing (0/25 filled)

**What it drives:** Determines which protocols are served and when based on lead time. Values: Progression (core → secondary), Complement, Choice.

**Suggested assignments:**

| Module | Suggested Sequencing | Rationale |
|---|---|---|
| Paula V modules (8) | Progression | All have 3 protocols that build in complexity — Protocol 1 is foundational, Protocol 2 adds practice, Protocol 3 deepens |
| Andrea F modules (3) | Complement | All 3 protocols are independent nutritional habits that complement each other |
| Jenna M modules (3) | Progression | Protocols build from isolated drills to integrated movement |
| Myra WIP modules (10) | TBD | Need protocols written first |

### 3. Weekly Frequency (0/25 filled)

**What it drives:** Protocol frequency caps based on user's available days/week.

**Suggested assignments based on protocol prescriptions already written:**

| Module | Suggested WeeklyFreq | Source |
|---|---|---|
| Staying Composed in High Pressure Moments | 3x | Protocol 3 prescribes 3x/week |
| Command Commitment in the Moment | 5x | Protocol 2 prescribes daily |
| Release the Shock | 5x | Protocol 1 prescribes daily |
| Focus on the Positive | 5x | Protocol 1 prescribes daily |
| Build Capacity for Uncertainty | 5x | Protocol 1 prescribes daily |
| Command Outcomes When You Don't Own the Room | 3x | Protocols prescribe 3x/week |
| Concentration Power | 5x | Protocols 1 & 2 prescribe daily |
| Mental Reset Micro-Breaks | 5x | As needed, daily baseline |
| Better Breakfasts | 7x | Daily nutrition habit |
| Anti-Inflammatory Eating | 7x | Daily nutrition pattern |
| Eating for Cognitive Clarity | 7x | Daily nutrition pattern |
| Walk with Command | 3x | Progressive training, needs rest days |
| Embodying Authority | 5x | Daily practice, pre-meeting use |
| Train with Intention | 3x | Training-session aligned |

### 4. Daily Frequency (0/25 filled)

**Suggested: 1x for all modules.** Most protocols are designed as single daily sessions. Some (like Mental Reset Micro-Breaks) could be 2-3x.

### 5. Time to Result (3/25 filled — only Andrea's)

**Suggested assignments:**

| Module | Suggested TimetoResult | Rationale |
|---|---|---|
| Paula V mindset modules | Moderate (1-2 weeks of consistent practice) | Neurological habit formation takes repetition |
| Jenna M physical modules | Moderate (2-4 weeks) | Physical adaptation requires progressive loading |
| Myra leadership modules | Varies | Depends on practice frequency and stakes of application |

### 6. Experience Level (3/25 filled — only Andrea's)

**Suggested assignments:**

| Module | Suggested Level | Rationale |
|---|---|---|
| Staying Composed in High Pressure Moments | Beginner | Accessible breathing/grounding techniques |
| Command Commitment in the Moment | Beginner | Simple action-oriented drills |
| Release the Shock | Beginner | Basic sensory awareness |
| Focus on the Positive | Beginner | Journaling and visualization |
| Build Capacity for Uncertainty | Intermediate | Requires comfort with discomfort |
| Command Outcomes When You Don't Own the Room | Intermediate | Requires existing communication foundation |
| Concentration Power | Beginner | Universal attention training |
| Mental Reset Micro-Breaks | Beginner | Low barrier to entry |
| Walk with Command | Intermediate | Physical balance/coordination required |
| Embodying Authority | Beginner | Postural awareness is accessible |
| Train with Intention | Beginner | Mindful movement basics |

### 7. Intensity (3/25 filled — only Andrea's)

**Suggested assignments:**

| Module | Suggested Intensity | Rationale |
|---|---|---|
| Staying Composed in High Pressure Moments | Moderate | Stress simulation drills involve discomfort |
| Command Commitment in the Moment | Moderate | Requires pushing through hesitation |
| Release the Shock | Low | Gentle sensory and breathing work |
| Focus on the Positive | Low | Journaling and visualization |
| Build Capacity for Uncertainty | Moderate | Deliberate discomfort practice |
| Command Outcomes When You Don't Own the Room | Moderate | Social pressure practice |
| Concentration Power | Low | Seated attention training |
| Mental Reset Micro-Breaks | Low | Restorative by design |
| Walk with Command | Moderate | Physical balance challenges |
| Embodying Authority | Low | Postural holds, low physical demand |
| Train with Intention | Moderate | Intentional physical training |

### 8. Daily Time (3/25 filled — only Andrea's)

**Suggested assignments based on protocol steps:**

| Module | Suggested DailyTime | Rationale |
|---|---|---|
| Staying Composed in High Pressure Moments | 10-15 min | 5 breath cycles + grounding + drill |
| Command Commitment in the Moment | 5-10 min | Quick decision drills |
| Release the Shock | 5-10 min | Alarm + label + shake sequence |
| Focus on the Positive | 10-15 min | Journaling + visualization |
| Build Capacity for Uncertainty | 15-20 min | 20-min delay practice + breathing |
| Command Outcomes When You Don't Own the Room | 10-15 min | Speaking practice + chaos sitting |
| Concentration Power | 15-30 min | 2-min focus + Pomodoro sprints |
| Mental Reset Micro-Breaks | 5-10 min | Short by design |
| Walk with Command | 15-20 min | Physical drill progression |
| Embodying Authority | 10-15 min | Posture drills and holds |
| Train with Intention | 15-20 min | Body scan + intentional reps |

---

## WIP Modules — Suggested Content

The following 11 modules have titles and varying levels of detail. Here are suggestions for filling out the remaining fields.

### Communicate with Impact (Myra)

- **Overview:** Master the art of purposeful communication — from clarity of message to emotional resonance — so your words move people to action, not just understanding.
- **PowerPillar1:** Empower
- **PowerPillar2:** Power Through
- **Protocol1 (Anchor):** Purpose: Clarify your intent before speaking. Steps: Before any key communication, write one sentence answering: "What do I want the listener to do, feel, or understand?" Align your opening statement to that intent. Prescription: Before every meeting, presentation, or difficult conversation. Expected Outcome: Sharper, more purposeful delivery.
- **Protocol2:** Purpose: Eliminate filler and strengthen delivery. Steps: Record yourself delivering a 2-minute message; listen back noting filler words, pace, and clarity; re-deliver with corrections. Prescription: 2x/week. Expected Outcome: Increased verbal precision and confidence.
- **Protocol3:** Purpose: Read and adapt to your audience in real time. Steps: During conversations, pause every 3 minutes to check audience energy (body language, questions, engagement); adjust pace, tone, or content accordingly. Prescription: In every key interaction. Expected Outcome: Higher engagement and message retention.
- **Modifications:** Use voice memos instead of video for recording practice; start with low-stakes conversations.
- **Coach Tip:** "Impact isn't about volume or vocabulary — it's about intention. Know what you want before you open your mouth, say it with conviction, and then stop. The pause after your point lands is where influence lives."
- **Intensity:** Moderate
- **DailyTime:** 10-15 min
- **Experience Level:** Intermediate

### Storytelling to Influence Decisions (Myra)

- **Overview:** Learn to craft and deliver stories that frame decisions, build alignment, and make your perspective unforgettable. Storytelling is not embellishment — it's strategic communication.
- **CoreConcepts:** 1. Stories activate empathy and memory more than data alone. 2. A well-structured narrative frames the decision before the ask. 3. Personal stakes make abstract ideas concrete and urgent.
- **PowerPillar1:** Empower
- **PowerPillar2:** Power Up
- **GoalCategory1:** Impact & Influence
- **GoalCategory2:** Commanding Presence
- **Outcomes:** - Deliver a 90-second story that clearly frames a decision. - Increase audience recall of your key message. - Build alignment faster in group decision-making settings.
- **Protocol1 (Anchor):** Purpose: Build a personal story bank. Steps: Identify 5 professional moments where you made a difficult call or learned something unexpected; for each, write: the situation, the tension, the outcome, and the lesson. Prescription: One-time exercise, revisit monthly. Expected Outcome: Ready-to-deploy stories for any context.
- **Protocol2:** Purpose: Structure stories for maximum impact. Steps: Use the Situation-Complication-Resolution framework; practice delivering one story in under 90 seconds; record and refine. Prescription: 2x/week. Expected Outcome: Tighter, more compelling narratives.
- **Protocol3:** Purpose: Deploy stories strategically. Steps: Before a key meeting, identify the decision at stake; select a story from your bank that frames the outcome you want; practice the transition from story to ask. Prescription: Before high-stakes interactions. Expected Outcome: Decisions aligned with your perspective.
- **Modifications:** Start with written stories before verbal delivery; use partner practice for feedback.
- **Coach Tip:** "Data convinces the mind, but stories move the heart. When you need people to act — not just agree — lead with a story that makes the stakes real. The best leaders don't just present information; they frame the narrative."
- **Intensity:** Low
- **DailyTime:** 10-15 min
- **Experience Level:** Beginner

### Mobilize a Team (Myra)

- **Overview (existing concepts are strong, extending):** Rally your team around a shared mission by engaging all levels in problem-solving, removing barriers, and celebrating forward momentum.
- **PowerPillar1:** Empower
- **PowerPillar2:** Power Through
- **Protocol1 (Anchor):** Purpose: Align the team to the mission. Steps: Open your next team meeting with one question: "What is the one thing we need to achieve this week, and what's blocking it?" Listen without solving for 3 minutes. Then co-create the action plan. Prescription: Weekly. Expected Outcome: Shared ownership and faster blocker resolution.
- **Protocol2:** Purpose: Practice servant leadership. Steps: Identify one barrier a team member is facing; remove it or escalate it within 24 hours; communicate back to the team what was done and why. Prescription: 2x/week. Expected Outcome: Increased trust and team velocity.
- **Protocol3:** Purpose: Celebrate incremental wins. Steps: End each week with a 5-minute recognition moment — name a specific win, the person behind it, and why it mattered. Prescription: Weekly. Expected Outcome: Sustained motivation and engagement.
- **Modifications:** For remote teams, use async check-ins (Slack/email) with the same question framework.
- **Coach Tip:** "The best leaders don't have all the answers — they create the conditions for answers to emerge. Engage, empower, and get out of the way. Your job is to clear the path, not walk it for them."
- **Intensity:** Moderate
- **DailyTime:** 15-20 min
- **Experience Level:** Intermediate

### Cool the Tension and Put People at Ease (Myra)

- **Overview:** De-escalate charged interactions and create psychological safety so productive dialogue can happen. This module trains you to regulate your own state first, then shift the energy of the room.
- **CoreConcepts:** 1. Your calm is contagious — regulate yourself first and the room follows. 2. Validation disarms defensiveness faster than logic. 3. Pace and tone matter more than content in tense moments.
- **PowerPillar1:** Power Down
- **PowerPillar2:** Empower
- **GoalCategory1:** Emotional Resilience
- **GoalCategory2:** Impact & Influence
- **Outcomes:** - Reduce visible tension in group interactions within 2 minutes. - Increase team willingness to voice disagreements constructively. - Maintain composure during conflict without withdrawing or escalating.
- **Protocol1 (Anchor):** Purpose: Self-regulate before intervening. Steps: When tension rises, pause; take 3 slow breaths; soften your shoulders and jaw; lower your vocal tone by one notch. Prescription: In every charged interaction. Expected Outcome: Faster return to productive dialogue.
- **Protocol2:** Purpose: Validate before redirecting. Steps: Name what you're hearing ("It sounds like this feels urgent/frustrating/unclear"); acknowledge it without agreeing or fixing; then redirect: "Here's what I think we can do right now." Prescription: In tense conversations. Expected Outcome: Reduced defensiveness, faster alignment.
- **Protocol3:** Purpose: Set the tone proactively. Steps: In meetings with known tension, open with a grounding statement ("I want us all to walk out of here aligned") and a process agreement ("Let's hear each perspective for 2 minutes before responding"). Prescription: Before difficult meetings. Expected Outcome: Lower conflict intensity.
- **Modifications:** Practice with low-stakes situations first; use written scripts before live delivery.
- **Coach Tip:** "Tension isn't the enemy — unmanaged tension is. Your ability to stay grounded when others can't is your superpower. Breathe first, speak second, and watch the room shift."
- **Intensity:** Moderate
- **DailyTime:** 5-10 min
- **Experience Level:** Intermediate

### Measured Reactions in Unexpected Situations (Myra)

*Has overview, core concepts, and outcomes. Needs protocols.*

- **PowerPillar1:** Power Through
- **PowerPillar2:** Empower
- **Protocol1 (Anchor):** Purpose: Create a response gap. Steps: When blindsided, use the 3-second rule — pause, take one breath, and ask a clarifying question before responding ("Help me understand — what specifically are you seeing?"). Prescription: In every unexpected situation. Expected Outcome: Fewer reactive responses.
- **Protocol2:** Purpose: Practice under simulation. Steps: Have a colleague deliver unexpected feedback or a curveball question during a practice session; apply the 3-second rule; debrief what you felt and how you responded. Prescription: 2x/week. Expected Outcome: Faster composure recovery.
- **Protocol3:** Purpose: Post-event reflection. Steps: After an unexpected situation, journal: What happened? What did I feel? What did I do? What would I do differently? Prescription: After each incident. Expected Outcome: Continuous improvement in reactive patterns.
- **Modifications:** Start with low-stakes simulations; use written reflection before verbal debriefs.
- **Coach Tip:** "The moment that catches you off guard is the moment that reveals your training. Don't react — respond. The pause between stimulus and response is where your power lives."
- **Intensity:** Moderate
- **DailyTime:** 10-15 min
- **Experience Level:** Intermediate

### Make Decisions with Confidence (Myra)

- **Overview:** Build the muscle of decisive action by training yourself to gather sufficient (not perfect) information, commit fully, and course-correct without self-judgment.
- **CoreConcepts:** 1. Decisiveness improves with practice, not with more data. 2. Good enough information, acted on quickly, beats perfect information acted on late. 3. Post-decision commitment matters more than pre-decision analysis.
- **PowerPillar1:** Empower
- **PowerPillar2:** Power Through
- **GoalCategory1:** Decision Making & Taking Action
- **GoalCategory2:** Critical Thinking
- **Outcomes:** - Reduce decision time on recurring choices by 50%. - Increase follow-through on decisions without second-guessing. - Report higher confidence in judgment calls under pressure.
- **Protocol1 (Anchor):** Purpose: Train the decision muscle. Steps: For low-stakes daily decisions, set a 60-second timer; gather available information; decide; move on without revisiting. Prescription: 3x/day. Expected Outcome: Faster decision-making habit.
- **Protocol2:** Purpose: Apply the 70% rule. Steps: Before a key decision, list what you know vs. what you don't; if you have 70% of the information, decide now; document what you'd need to course-correct. Prescription: For all medium/high-stakes decisions. Expected Outcome: Reduced analysis paralysis.
- **Protocol3:** Purpose: Build post-decision resilience. Steps: After a decision, journal: "I chose X because Y. If it doesn't work, I will Z." Refuse to revisit for 24 hours. Prescription: After every significant decision. Expected Outcome: Reduced second-guessing.
- **Modifications:** Start with decisions that have low consequences; build toward higher stakes gradually.
- **Coach Tip:** "Confidence doesn't come from being right every time — it comes from trusting yourself to handle whatever comes next. Decide, commit, adjust. That's the cycle. Stop waiting for certainty; it doesn't exist."
- **Intensity:** Low
- **DailyTime:** 5-10 min
- **Experience Level:** Beginner

### Increase Your Gravitational Pull with Colleagues (Myra)

- **Overview:** Build the kind of professional presence that draws people in — not through authority, but through reliability, curiosity, and genuine engagement. This module trains the habits that make colleagues seek you out.
- **CoreConcepts:** 1. Influence is built through consistent micro-interactions, not grand gestures. 2. Curiosity about others' perspectives builds trust faster than expertise. 3. Being the person who follows through creates magnetic credibility.
- **PowerPillar1:** Empower
- **PowerPillar2:** Power Up
- **GoalCategory1:** Impact & Influence
- **GoalCategory2:** Commanding Presence
- **Outcomes:** - Be sought out for input on decisions outside your direct responsibility. - Increase cross-functional collaboration invitations. - Build a reputation as someone who delivers and elevates others.
- **Protocol1 (Anchor):** Purpose: Build the curiosity habit. Steps: In every meeting or 1:1, ask one genuine question about the other person's challenge or perspective before sharing your own. Listen fully before responding. Prescription: Daily. Expected Outcome: Deeper professional relationships.
- **Protocol2:** Purpose: Close every loop. Steps: Track every commitment you make in a day; close each one within 24 hours or proactively communicate a new timeline. Prescription: Daily. Expected Outcome: Reputation as someone who delivers.
- **Protocol3:** Purpose: Elevate others publicly. Steps: In group settings, name a colleague's contribution before adding your own ("Building on what [name] said..."). Prescription: In every group interaction. Expected Outcome: Increased trust and reciprocal support.
- **Modifications:** Start with one relationship or team; expand as the habit solidifies.
- **Coach Tip:** "Influence isn't about being the loudest voice — it's about being the one people trust. Show up curious, follow through relentlessly, and lift others as you rise. Gravity follows those who give more than they take."
- **Intensity:** Low
- **DailyTime:** 5-10 min
- **Experience Level:** Beginner

### Focus on What Matters Most (Myra)

- **Overview:** Cut through noise, competing priorities, and urgency bias to identify and protect the work that actually moves the needle. This module builds the discipline of strategic focus.
- **CoreConcepts:** 1. Urgency and importance are not the same thing. 2. Saying no to good things is required to say yes to great things. 3. Daily intention-setting prevents reactive spiraling.
- **PowerPillar1:** Power Down
- **PowerPillar2:** Empower
- **GoalCategory1:** Prioritization & Time Mngmt.
- **GoalCategory2:** Critical Thinking
- **Outcomes:** - Identify the single highest-leverage task each day. - Reduce time spent on reactive work by 25%. - Report greater sense of progress on meaningful goals.
- **Protocol1 (Anchor):** Purpose: Set the day's anchor. Steps: Before opening email/Slack, write: "The one thing that matters most today is ___." Protect the first 90 minutes for that task. Prescription: Daily. Expected Outcome: Consistent progress on high-value work.
- **Protocol2:** Purpose: Audit your time. Steps: At the end of each day, categorize your time: strategic (moved the needle), reactive (responded to others), or maintenance (kept things running). Aim for 40%+ strategic. Prescription: Daily, 5 minutes. Expected Outcome: Awareness of time allocation patterns.
- **Protocol3:** Purpose: Practice strategic no. Steps: When a new request arrives, ask: "Does this serve my top priority this week?" If no, defer, delegate, or decline with a clear reason. Prescription: As needed. Expected Outcome: Protected focus time.
- **Modifications:** Use a physical notebook if digital tools create distraction; pair with a weekly review.
- **Coach Tip:** "Busy is not productive. The most powerful leaders aren't the ones doing the most — they're the ones doing the right things. Protect your focus like it's your most valuable asset, because it is."
- **Intensity:** Low
- **DailyTime:** 10-15 min
- **Experience Level:** Beginner

### Build Your Personal Brand (TBD)

- **Overview:** Define and project a professional identity that is authentic, memorable, and strategically aligned to your goals. Your personal brand isn't vanity — it's visibility with purpose.
- **CoreConcepts:** 1. Your brand is what people say about you when you're not in the room. 2. Consistency across channels builds recognition and trust. 3. Authenticity is more compelling than polish.
- **PowerPillar1:** Empower
- **PowerPillar2:** Power Up
- **GoalCategory1:** Impact & Influence
- **GoalCategory2:** Commanding Presence
- **Outcomes:** - Articulate your professional value proposition in one clear sentence. - Increase visibility in your industry or organization. - Receive feedback that your external presence matches your internal intent.
- **Protocol1 (Anchor):** Purpose: Define your core message. Steps: Answer: "What do I want to be known for? What problem do I solve? Who needs to know?" Write a 1-sentence positioning statement. Prescription: One-time exercise, revisit quarterly. Expected Outcome: Clear, deployable self-description.
- **Protocol2:** Purpose: Audit your digital presence. Steps: Review your LinkedIn, email signature, and any public profiles; ensure they align with your positioning statement; update one element per week. Prescription: Weekly for 4 weeks. Expected Outcome: Consistent external presence.
- **Protocol3:** Purpose: Create visibility moments. Steps: Identify one opportunity per week to share your perspective publicly (comment on a post, speak up in a meeting, share an insight with a peer). Prescription: Weekly. Expected Outcome: Increased recognition in your domain.
- **Modifications:** Start with internal visibility before external; use written formats if speaking feels high-stakes.
- **Coach Tip:** "Your brand isn't your title or your resume — it's the feeling people have after interacting with you. Be intentional about that feeling. Show up consistently, share generously, and let your work speak loudly."
- **Intensity:** Low
- **DailyTime:** 10-15 min
- **Experience Level:** Beginner

### Control the Conversation (Myra)

*Has overview, core concepts, and outcomes. Needs protocols.*

- **PowerPillar1:** Empower
- **PowerPillar2:** Power Through
- **Protocol1 (Anchor):** Purpose: Set the frame before the conversation starts. Steps: Before key meetings, write your objective in one sentence; open with it ("Here's what I'd like us to accomplish today..."); revisit it if the conversation drifts. Prescription: Before every important meeting. Expected Outcome: Conversations that reach your intended outcome.
- **Protocol2:** Purpose: Master the bridge. Steps: When the conversation veers off track, use a bridging phrase: "That's an important point — and it connects to what we need to decide about [your topic]." Practice bridging in low-stakes conversations. Prescription: 3x/week. Expected Outcome: Smooth redirection without resistance.
- **Protocol3:** Purpose: Close with commitment. Steps: In the final 2 minutes of any conversation, summarize: "Here's what I heard us agree on..." and assign next steps with names and dates. Prescription: Every conversation. Expected Outcome: Clear accountability and follow-through.
- **Modifications:** Use written agendas as training wheels; practice bridging with a partner first.
- **Coach Tip:** "Controlling a conversation isn't about talking more — it's about knowing where it needs to go and steering with precision. Set the destination, guide the journey, and close with clarity."
- **Intensity:** Moderate
- **DailyTime:** 10-15 min
- **Experience Level:** Intermediate

### Trust Your Interpersonal Instincts (Myra)

- **Overview:** Develop confidence in your ability to read people, situations, and dynamics — and act on that read. This module trains you to trust the signals your experience is already sending you.
- **CoreConcepts:** 1. Intuition is pattern recognition built from experience — it deserves trust, not dismissal. 2. Emotional data is real data — learn to read it without being ruled by it. 3. The gap between sensing something and acting on it is where courage lives.
- **PowerPillar1:** Power Down
- **PowerPillar2:** Empower
- **GoalCategory1:** Emotional Resilience
- **GoalCategory2:** Impact & Influence
- **Outcomes:** - Increase confidence in reading interpersonal dynamics. - Act on gut instinct more quickly in professional settings. - Report fewer instances of "I knew I should have said something."
- **Protocol1 (Anchor):** Purpose: Build awareness of your signals. Steps: After key interactions, journal: "What did I sense? What did I do with that information? What would I do differently?" Prescription: Daily. Expected Outcome: Stronger connection between intuition and action.
- **Protocol2:** Purpose: Practice acting on reads. Steps: In your next 3 interactions, identify one moment where you sense something unspoken; name it gently ("I'm sensing there might be more to this — am I reading that right?"). Prescription: 3x/week. Expected Outcome: Validated instincts and deeper conversations.
- **Protocol3:** Purpose: Distinguish intuition from anxiety. Steps: When you have a strong gut feeling, pause and ask: "Is this pattern recognition or fear?" If it's pattern recognition (based on experience), act on it. If it's fear (based on worst-case thinking), breathe and reassess. Prescription: As needed. Expected Outcome: More accurate reads and fewer false alarms.
- **Modifications:** Start with low-stakes social situations; build toward professional high-stakes.
- **Coach Tip:** "Your instincts have been trained by every interaction you've ever had. Stop second-guessing them. The women who command rooms aren't the ones with the most data — they're the ones who trust what they already know."
- **Intensity:** Moderate
- **DailyTime:** 10-15 min
- **Experience Level:** Intermediate

---

## Goal Categories Without Modules — Suggested New Modules

Five goal categories in the Goal Categories sheet have zero modules assigned. These need at least 2-3 modules each for the logic engine to generate meaningful plans.

### Physical Endurance (0 modules)

**Suggested modules:**
1. **"Build Your Endurance Base"** (Jenna M) — Progressive cardio and stamina building for women who want to go longer and recover faster. Power Pillars: Power Up + Power Through.
2. **"Mental Grit for Physical Limits"** (Paula V) — Train the mind to push through discomfort and maintain form when fatigue hits. Power Pillars: Power Through + Empower.
3. **"Recovery as Performance"** (Andrea F) — Nutrition and rest strategies that turn recovery into your competitive advantage. Power Pillars: Power Down + Power Up.

### Flexibility & Mobility (0 modules)

**Suggested modules:**
1. **"Morning Mobility Flow"** (Jenna M) — Daily movement sequences to release stiffness and build range of motion for confidence in your body. Power Pillars: Power Up + Power Down.
2. **"Desk-to-Podium Reset"** (Jenna M) — Quick mobility sequences to undo desk posture before presentations and high-visibility moments. Power Pillars: Power Down + Empower.
3. **"Anti-Inflammatory Movement + Nutrition"** (Andrea F) — Pairing joint-supportive nutrition with movement for lasting flexibility gains. Power Pillars: Power Up + Power Through.

### Prioritization & Time Management (0 modules — partially covered by "Focus on What Matters Most")

**Suggested modules:**
1. **"Time Blocking for High Performers"** (Myra) — Build a weekly rhythm that protects deep work, manages energy, and eliminates decision fatigue. Power Pillars: Power Down + Empower.
2. **"Energy Mapping: Work With Your Biology"** (Andrea F) — Align your highest-value work with your circadian energy peaks. Power Pillars: Power Up + Power Down.

### Personal Relationships (0 modules)

**Suggested modules:**
1. **"Show Up Present, Not Perfect"** (Myra) — Build the habit of full presence in personal relationships by managing work spillover and emotional availability. Power Pillars: Power Down + Empower.
2. **"Repair and Reconnect"** (Paula V) — Tools for navigating ruptures in close relationships with composure and vulnerability. Power Pillars: Power Down + Empower.

### Relationship Boundaries (0 modules)

**Suggested modules:**
1. **"The Boundary Blueprint"** (Myra) — Identify, communicate, and maintain boundaries that protect your energy without damaging relationships. Power Pillars: Empower + Power Down.
2. **"Saying No Without Guilt"** (Paula V) — Train the emotional and verbal skills to decline requests with clarity and self-respect. Power Pillars: Empower + Power Through.

---

## Recommended Module ID Scheme

Currently only Paula V's modules lack IDs (they were never assigned) and Myra's are marked "WIP". Suggested scheme based on Power Pillar prefix:

- **PU** = Power Up primary
- **PT** = Power Through primary
- **PD** = Power Down primary
- **EM** = Empower primary
- Followed by 4-digit number: `EM0001`, `PT0002`, etc.

This matches the ID pattern referenced in the roadmap doc (PU0002, PD0002, EM0002, PT0002).

---

## Summary of What's Needed Before Import

| Priority | Item | Effort |
|---|---|---|
| **Critical** | Assign Module IDs to all 25 modules | Low — apply naming scheme |
| **Critical** | Fill Module Type for all 25 modules | Low — suggestions above |
| **Critical** | Fill Protocol Sequencing for all 25 modules | Low — suggestions above |
| **Critical** | Fill WeeklyFreq for all 25 modules | Low — derivable from protocols |
| **Critical** | Fill Intensity for 22 modules (3 done) | Low — suggestions above |
| **Critical** | Fill DailyTime for 22 modules (3 done) | Low — suggestions above |
| **High** | Write protocols for 11 WIP modules | High — suggestions above can be used as starting point |
| **High** | Fill Experience Level for 22 modules | Low — suggestions above |
| **High** | Add modules for 5 empty goal categories | High — at least 2-3 per category |
| **Medium** | Fill TimetoResult for 22 modules | Low |
| **Medium** | Fill DailyFreq for all 25 modules | Low — mostly 1x |
| **Low** | Fill Video field | N/A until video content exists |
| **Low** | Fill Sources for non-Jenna modules | Medium — research needed |
