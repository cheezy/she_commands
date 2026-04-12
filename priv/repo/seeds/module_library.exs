# Module Library Seed Script
#
# Seeds goal categories (15) and modules (25) from the She Commands
# Module Library spreadsheet. Idempotent — safe to run multiple times.
#
# Run with: mix run priv/repo/seeds/module_library.exs

alias SheCommands.Repo
alias SheCommands.Intake.GoalCategory
alias SheCommands.Modules
alias SheCommands.Modules.Module

# =============================================================================
# Goal Categories (15)
# =============================================================================

goal_categories = [
  %{
    name: "Commanding Presence",
    slug: "commanding-presence",
    description:
      "You build confidence, executive presence, and speak with authority and clarity.",
    outcome_power_up:
      "Hone focus, anti-slump nutrition, caffeine control, hydration, self-motivation",
    outcome_power_through: "Posture, body language, maintain composure",
    outcome_power_down: "Eliminate distractions, breath control, anxiety release",
    outcome_empower:
      "Project confidence, communicate with clarity, authentic leadership, overcoming imposter syndrome",
    position: 1
  },
  %{
    name: "Habit Mastery & Self-Discipline",
    slug: "habit-mastery",
    description: "You build and sustain habits that serve long-term goals.",
    outcome_power_up:
      "Morning fuel, consistent meals, sugar discipline, hydration, mindful eating, self-motivation",
    outcome_power_through: "Daily movement, healthy food alternatives, self-motivation",
    outcome_power_down: "Bedtime routine, digital detox, daily micro breaks, affirmations",
    outcome_empower: "Self-accountability, habit tracking, goal setting",
    position: 2
  },
  %{
    name: "Decision Making & Taking Action",
    slug: "decision-making-action",
    description:
      "You think clearly under pressure and take outcome-driven, confident action.",
    outcome_power_up:
      "Mood-stabilizing foods, hone focus, anti-slump nutrition, caffeine control, hydration",
    outcome_power_through:
      "Hand-eye coordination, quick reasoning, performance under pressure, anti-analysis paralysis, mental endurance",
    outcome_power_down:
      "Emotional regulation, deep sleep, anxiety release, eliminate distractions",
    outcome_empower: "Bias awareness, results orientation, reading the room",
    position: 3
  },
  %{
    name: "Emotional Resilience",
    slug: "emotional-resilience",
    description:
      "You navigate stress, setbacks, and internal narratives with strength and recovery.",
    outcome_power_up: "Mood-stabilizing foods, caffeine control",
    outcome_power_through:
      "Tension release movement, performance under pressure, mental endurance",
    outcome_power_down:
      "Nervous system recovery, emotional reset, anxiety release, grounding and perspective",
    outcome_empower: "Mental agility, leading with empathy, goal setting",
    position: 4
  },
  %{
    name: "Physical Vitality & Strength",
    slug: "physical-vitality",
    description: "You boost energy, strength, and physical capacity.",
    outcome_power_up:
      "Protein optimization, fueling for performance, hydration, joint-support nutrition",
    outcome_power_through:
      "Core strength, mobility, endurance training, explosive movement, pushing your limits",
    outcome_power_down:
      "Stretching, deep sleep, recovery and injury prevention, body awareness",
    outcome_empower:
      "Motivation maintenance, goal setting, overcoming imposter syndrome",
    position: 5
  },
  %{
    name: "Impact & Influence",
    slug: "impact-influence",
    description:
      "You shape decisions, lead initiatives, and grow credibility in your domain.",
    outcome_power_up:
      "Hone focus, fueling for long days, mood-stabilizing foods, self-motivation, nurture curiosity",
    outcome_power_through:
      "Posture, body language, performance under pressure, resilience under pressure",
    outcome_power_down:
      "Boundary setting, emotional reset, eliminate distractions, affirmations",
    outcome_empower:
      "Persuasive storytelling, leadership communication, knowledge/learning hacks, constructive disruption",
    position: 6
  },
  %{
    name: "Personal Relationships",
    slug: "personal-relationships",
    description:
      "You show up more grounded, present, and intentional in your closest relationships.",
    outcome_power_up: "",
    outcome_power_through: "",
    outcome_power_down: "",
    outcome_empower: "",
    position: 7
  },
  %{
    name: "Stress & Anxiety",
    slug: "stress-anxiety",
    description:
      "You manage stress with tools and regain a sense of calm, clarity, and control on demand.",
    outcome_power_up: "Caffeine control, blood sugar regulation, hydration",
    outcome_power_through:
      "Tension release movement, breath control, performance under pressure, mental endurance",
    outcome_power_down:
      "Nervous system reset, mindfulness habits, sleep optimization, deep relaxation, stress journaling",
    outcome_empower:
      "Thought reframing, reframing pressure, perspective shift, self-trust, letting go of perfectionism",
    position: 8
  },
  %{
    name: "Prioritization & Time Mngmt.",
    slug: "prioritization-time",
    description:
      "You start executing what matters most with goal setting and time tracking tools.",
    outcome_power_up:
      "Energy mapping, meal prep efficiency, nutrition planning, cognitive clarity foods",
    outcome_power_through:
      "Morning activation routine, micro-workouts, focus intervals, productivity movement breaks",
    outcome_power_down:
      "Evening decompression, sleep scheduling, boundary rituals, tech cut-off",
    outcome_empower:
      "Decision hierarchy, value alignment, time blocking mindset, focus discipline, eliminating noise",
    position: 9
  },
  %{
    name: "Flexibility & Mobility",
    slug: "flexibility-mobility",
    description:
      "You release stiffness to move with greater agility and confidence.",
    outcome_power_up:
      "Hydration for joints, anti-inflammatory nutrition, magnesium balance, recovery fuel",
    outcome_power_through:
      "Stretching circuits, functional mobility, dynamic warmups, balance drills, full-range movement",
    outcome_power_down:
      "Relaxation stretch routines, restorative yoga, fascia release, breath-stretch link",
    outcome_empower:
      "Adaptability mindset, patience in progress, movement confidence, releasing rigidity, self-acceptance",
    position: 10
  },
  %{
    name: "Relationship Boundaries",
    slug: "relationship-boundaries",
    description:
      "You set clear boundaries, speak your needs, and navigate conflict with confidence.",
    outcome_power_up: "",
    outcome_power_through: "",
    outcome_power_down: "",
    outcome_empower: "",
    position: 11
  },
  %{
    name: "Team Leadership",
    slug: "team-leadership",
    description:
      "You lead others with clarity, cohesion, and momentum — aligning values, roles, and energy toward shared goals.",
    outcome_power_up:
      "Energy management for teams, brain food for focus, meeting stamina, hydration for alertness",
    outcome_power_through:
      "Presence in meetings, team energizers, movement for focus, micro-break activation",
    outcome_power_down:
      "Post-meeting reflection, mindfulness under pressure, calm leadership reset",
    outcome_empower:
      "Leading with clarity, empowering others, decision authority, feedback with empathy, vision alignment",
    position: 12
  },
  %{
    name: "Life Force Reclamation",
    slug: "life-force-reclamation",
    description:
      "You reignite your spark and reclaim a rhythm that feels inspired — not just functional.",
    outcome_power_up: "",
    outcome_power_through: "",
    outcome_power_down: "",
    outcome_empower: "",
    position: 13
  },
  %{
    name: "Critical Thinking",
    slug: "critical-thinking",
    description:
      "You cut through noise and make decisions that are strategic, sound, and defendable.",
    outcome_power_up:
      "Brain-boosting foods, hydration clarity, energy for focus, sustained mental stamina",
    outcome_power_through:
      "Concentration training, brain-body connection, endurance for focus, mental stamina workouts",
    outcome_power_down:
      "Rest for cognition, digital detox, breathing for clarity, meditation for insight",
    outcome_empower:
      "Perspective analysis, logic vs emotion, bias awareness, strategic reflection, curiosity mindset",
    position: 14
  },
  %{
    name: "Physical Endurance",
    slug: "physical-endurance",
    description:
      "You build stamina — physical and mental — so you can go longer, recover faster, and meet the moment with strength.",
    outcome_power_up:
      "Endurance fueling, electrolytes, carb timing, hydration balance, recovery nutrition",
    outcome_power_through:
      "Progressive endurance training, breathing control, pacing strategy, mobility support, mental grit drills",
    outcome_power_down:
      "Recovery and rest days, active recovery, sleep optimization, stretching for repair",
    outcome_empower:
      "Mental endurance, commitment mindset, goal resilience, grit, perseverance training",
    position: 15
  }
]

IO.puts("\n=== Seeding Goal Categories ===")

seeded_categories =
  for attrs <- goal_categories do
    case Repo.get_by(GoalCategory, slug: attrs.slug) do
      nil ->
        {:ok, cat} =
          %GoalCategory{}
          |> GoalCategory.changeset(attrs)
          |> Repo.insert()

        IO.puts("  Created: #{cat.name}")
        cat

      existing ->
        {:ok, cat} =
          existing
          |> GoalCategory.changeset(attrs)
          |> Repo.update()

        IO.puts("  Updated: #{cat.name}")
        cat
    end
  end

# Build a lookup map by name for associating modules
category_map =
  seeded_categories
  |> Enum.map(fn cat -> {cat.name, cat} end)
  |> Map.new()

# Helper to look up categories by name
find_categories = fn names ->
  names
  |> Enum.map(fn name -> Map.get(category_map, name) end)
  |> Enum.reject(&is_nil/1)
end

# =============================================================================
# Modules (25) with Protocols and Goal Category Associations
# =============================================================================

IO.puts("\n=== Seeding Modules ===")

modules_data = [
  # --- Paula V (8 modules) ---
  %{
    attrs: %{
      module_id: "PD0001",
      contributor: "Paula V",
      title: "Staying Composed in High Pressure Moments",
      overview: "Train your nervous system to stay regulated under pressure using breath control, grounding techniques, and cognitive reframing.",
      core_concepts: "1. The stress response is physiological — manage the body first. 2. Grounding techniques anchor you in the present. 3. Cognitive reframing turns pressure into performance fuel.",
      power_pillar_1: :power_down,
      power_pillar_2: :power_through,
      module_type: :foundational,
      intensity: :moderate,
      daily_time: 15,
      weekly_freq: 3,
      daily_freq: 1,
      lead_time_fit: :short,
      experience_level: "Beginner",
      outcomes: "Reduce visible stress response in high-pressure situations. Maintain clear thinking when stakes are high. Recover faster after stressful events.",
      modifications: "Use seated grounding if standing is uncomfortable. Start with low-stakes practice environments.",
      coach_tip: "Pressure is a privilege — it means the moment matters. Train your body to stay in it.",
      coach_tip_attribution: "Paula V",
      outcome_keywords: ["Composure", "Calm", "Resilience"]
    },
    categories: ["Stress & Anxiety", "Emotional Resilience"],
    protocols: [
      %{position: 1, purpose: "Regulate the stress response through breath", steps: "Box breathing: 4-count inhale, 4-count hold, 4-count exhale, 4-count hold. Repeat 5 cycles.", prescription: "Before any high-pressure moment and daily practice", expected_outcome: "Lowered heart rate and clearer thinking within 2 minutes"},
      %{position: 2, purpose: "Ground yourself in the present moment", steps: "5-4-3-2-1 grounding: Name 5 things you see, 4 you hear, 3 you touch, 2 you smell, 1 you taste.", prescription: "When you feel anxiety rising, 2x daily", expected_outcome: "Interrupted anxiety spiral and return to present focus"},
      %{position: 3, purpose: "Reframe pressure as performance fuel", steps: "When you notice stress, say: 'This means I care. My body is preparing to perform.' Pair with 3 deep breaths.", prescription: "3x/week in high-pressure situations", expected_outcome: "Shifted relationship with pressure from threat to ally"}
    ]
  },
  %{
    attrs: %{
      module_id: "PT0001",
      contributor: "Paula V",
      title: "Command Commitment in the Moment",
      overview: "Build the habit of decisive action by training yourself to commit fully in the moment, even without perfect information.",
      core_concepts: "1. Hesitation erodes credibility. 2. Commitment is a muscle that strengthens with use. 3. Imperfect action beats perfect inaction.",
      power_pillar_1: :power_through,
      power_pillar_2: :empower,
      module_type: :foundational,
      intensity: :moderate,
      daily_time: 10,
      weekly_freq: 5,
      daily_freq: 1,
      lead_time_fit: :short,
      experience_level: "Beginner",
      outcomes: "Faster decision-making in meetings and conversations. Reduced second-guessing after commitments. Increased perception of confidence by others.",
      modifications: "Start with low-stakes decisions. Use a decision journal to track patterns.",
      coach_tip: "The moment you hesitate is the moment you lose the room. Commit first, refine later.",
      coach_tip_attribution: "Paula V",
      outcome_keywords: ["Decisiveness", "Confidence", "Action"]
    },
    categories: ["Decision Making & Taking Action", "Commanding Presence"],
    protocols: [
      %{position: 1, purpose: "Train the commitment reflex", steps: "In meetings, when you have a perspective, share it within 5 seconds. Don't wait for the perfect phrasing.", prescription: "Daily in meetings and conversations", expected_outcome: "Faster verbal commitment and reduced over-thinking"},
      %{position: 2, purpose: "Eliminate verbal hedging", steps: "Record yourself in a meeting. Count hedging words (maybe, I think, sort of). Replace with direct statements.", prescription: "Daily awareness practice", expected_outcome: "Sharper, more authoritative communication"},
      %{position: 3, purpose: "Build post-commitment resilience", steps: "After committing to a direction, write: 'I chose X because Y. If wrong, I will Z.' No revisiting for 24 hours.", prescription: "After every significant commitment", expected_outcome: "Reduced second-guessing and stronger follow-through"}
    ]
  },
  %{
    attrs: %{
      module_id: "PD0002",
      contributor: "Paula V",
      title: "Release the Shock",
      overview: "Process unexpected events and emotional shocks quickly so they don't derail your performance.",
      core_concepts: "1. Shock freezes the nervous system. 2. Physical movement releases stored tension. 3. Naming the emotion reduces its power.",
      power_pillar_1: :power_down,
      power_pillar_2: :power_through,
      module_type: :foundational,
      intensity: :low,
      daily_time: 10,
      weekly_freq: 5,
      daily_freq: 1,
      lead_time_fit: :short,
      experience_level: "Beginner",
      outcomes: "Faster recovery from unexpected news. Maintained composure after shocks. Reduced emotional carryover into subsequent interactions.",
      modifications: "Use seated shaking if standing is uncomfortable. Start with minor surprises before major shocks.",
      coach_tip: "Shock is stored in the body, not the mind. Move it through so it doesn't stay stuck.",
      coach_tip_attribution: "Paula V",
      outcome_keywords: ["Recovery", "Composure", "Resilience"]
    },
    categories: ["Emotional Resilience", "Stress & Anxiety"],
    protocols: [
      %{position: 1, purpose: "Alarm and label the shock", steps: "When shocked, pause. Say internally: 'I am experiencing shock.' This moves the experience from reactive to observed.", prescription: "Immediately after any unexpected event", expected_outcome: "Faster transition from reactive to responsive state"},
      %{position: 2, purpose: "Physical release", steps: "Shake your hands, roll your shoulders, stomp your feet gently. 30 seconds of deliberate physical movement.", prescription: "Within 5 minutes of the shock", expected_outcome: "Released physical tension and reduced freeze response"},
      %{position: 3, purpose: "Process and release", steps: "Write or voice-memo: What happened? What did I feel? What do I need right now? Then close it.", prescription: "Within 1 hour of the event", expected_outcome: "Emotional processing without rumination"}
    ]
  },
  %{
    attrs: %{
      module_id: "EM0001",
      contributor: "Paula V",
      title: "Focus on the Positive",
      overview: "Train your brain to scan for and amplify positive signals, building resilience and optimism without ignoring reality.",
      core_concepts: "1. The brain has a negativity bias. 2. Positivity is a trainable skill. 3. Gratitude rewires neural pathways.",
      power_pillar_1: :empower,
      power_pillar_2: :power_down,
      module_type: :foundational,
      intensity: :low,
      daily_time: 15,
      weekly_freq: 5,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Beginner",
      outcomes: "Increased optimism and forward focus. Reduced rumination on setbacks. Greater resilience in challenging periods.",
      modifications: "Use voice memos instead of journaling. Start with 1 positive instead of 3.",
      coach_tip: "Positivity isn't denial — it's choosing where to direct your attention. Train your brain to see what's working.",
      coach_tip_attribution: "Paula V",
      outcome_keywords: ["Optimism", "Resilience", "Gratitude"]
    },
    categories: ["Emotional Resilience", "Habit Mastery & Self-Discipline"],
    protocols: [
      %{position: 1, purpose: "Daily gratitude practice", steps: "Each morning, write 3 specific things you're grateful for. Be concrete: not 'my family' but 'the conversation I had with my daughter last night.'", prescription: "Daily, first thing", expected_outcome: "Trained positive scanning habit"},
      %{position: 2, purpose: "Positive event logging", steps: "At end of day, log 1 thing that went well and why. What did you do to contribute to it?", prescription: "Daily, end of day", expected_outcome: "Increased awareness of personal agency in positive outcomes"},
      %{position: 3, purpose: "Reframe setbacks", steps: "When something goes wrong, write: 'What can I learn? What's still working? What's one small step forward?'", prescription: "After each setback", expected_outcome: "Faster recovery and reduced catastrophizing"}
    ]
  },
  %{
    attrs: %{
      module_id: "PT0002",
      contributor: "Paula V",
      title: "Build Capacity for Uncertainty",
      overview: "Develop comfort with ambiguity and train yourself to operate effectively when outcomes are unknown.",
      core_concepts: "1. Certainty is an illusion. 2. Tolerance for uncertainty is trainable. 3. Action under uncertainty builds confidence.",
      power_pillar_1: :power_through,
      power_pillar_2: :empower,
      module_type: :foundational,
      intensity: :moderate,
      daily_time: 20,
      weekly_freq: 5,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Intermediate",
      outcomes: "Increased comfort with ambiguity. Faster action in uncertain situations. Reduced anxiety about unknowns.",
      modifications: "Start with low-stakes uncertainty. Use breathing exercises as a companion practice.",
      coach_tip: "Uncertainty is not a problem to solve — it's a condition to operate within. Build your capacity to sit with it.",
      coach_tip_attribution: "Paula V",
      outcome_keywords: ["Confidence", "Adaptability", "Courage"]
    },
    categories: ["Decision Making & Taking Action", "Emotional Resilience"],
    protocols: [
      %{position: 1, purpose: "Practice sitting with not-knowing", steps: "When you feel the urge to seek certainty, set a 20-minute timer. Don't research, ask, or decide. Just sit with the discomfort. Breathe.", prescription: "Daily", expected_outcome: "Increased tolerance for ambiguity"},
      %{position: 2, purpose: "Take action without full information", steps: "Identify one decision you've been postponing due to uncertainty. Make it today with the information you have.", prescription: "3x/week", expected_outcome: "Reduced analysis paralysis"},
      %{position: 3, purpose: "Reflect on uncertainty outcomes", steps: "Weekly, review decisions made under uncertainty. Note: What happened? Was it as bad as feared?", prescription: "Weekly", expected_outcome: "Evidence-based confidence in uncertain decision-making"}
    ]
  },
  %{
    attrs: %{
      module_id: "EM0002",
      contributor: "Paula V",
      title: "Command Outcomes When You Don't Own the Room",
      overview: "Influence decisions and outcomes in environments where you lack formal authority.",
      core_concepts: "1. Influence is about positioning, not power. 2. Strategic silence is a tool. 3. Alliances amplify your voice.",
      power_pillar_1: :empower,
      power_pillar_2: :power_through,
      module_type: :secondary,
      intensity: :moderate,
      daily_time: 15,
      weekly_freq: 3,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Intermediate",
      outcomes: "Increased influence in meetings where you're not the senior person. Better outcomes in cross-functional settings. Greater comfort speaking up in unfamiliar groups.",
      modifications: "Start with 1:1 influence before group settings. Use written pre-positioning (emails before meetings).",
      coach_tip: "You don't need to own the room to own the outcome. Position yourself before the meeting, speak with precision during it, and follow up after.",
      coach_tip_attribution: "Paula V",
      outcome_keywords: ["Influence", "Strategy", "Presence"]
    },
    categories: ["Impact & Influence", "Commanding Presence"],
    protocols: [
      %{position: 1, purpose: "Pre-position your perspective", steps: "Before key meetings, share your perspective with 1-2 allies. Frame it: 'Here's what I'm seeing — does this resonate?'", prescription: "Before every important meeting", expected_outcome: "Built-in support before the conversation starts"},
      %{position: 2, purpose: "Use strategic silence", steps: "In meetings, wait for 3 others to speak before contributing. When you do, build on what's been said: 'I'd like to add to what [name] said...'", prescription: "3x/week", expected_outcome: "Higher-impact contributions and perceived authority"},
      %{position: 3, purpose: "Master chaos sitting", steps: "When a meeting goes off the rails, stay calm. Wait for the reset moment. Then offer: 'Can I suggest we focus on [key question]?'", prescription: "In chaotic meetings", expected_outcome: "Become the person who brings clarity to confusion"}
    ]
  },
  %{
    attrs: %{
      module_id: "PU0001",
      contributor: "Paula V",
      title: "Concentration Power",
      overview: "Sharpen your ability to focus deeply, resist distraction, and sustain attention on what matters.",
      core_concepts: "1. Attention is a finite resource. 2. Focus is a muscle that weakens with distraction. 3. Single-tasking beats multi-tasking every time.",
      power_pillar_1: :power_up,
      power_pillar_2: :power_through,
      module_type: :foundational,
      intensity: :low,
      daily_time: 30,
      weekly_freq: 5,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Beginner",
      outcomes: "Longer sustained focus periods. Reduced susceptibility to distraction. Increased output quality during deep work.",
      modifications: "Start with 1-minute focus intervals. Use noise-canceling headphones if environment is distracting.",
      coach_tip: "Your phone is not a tool — it's a distraction machine. Put it in another room. Your focus will thank you.",
      coach_tip_attribution: "Paula V",
      outcome_keywords: ["Focus", "Clarity", "Productivity"]
    },
    categories: ["Habit Mastery & Self-Discipline", "Critical Thinking"],
    protocols: [
      %{position: 1, purpose: "Train sustained attention", steps: "Set a timer for 2 minutes. Focus on a single point (candle, dot, breath). When attention wanders, gently return. Build to 5 minutes.", prescription: "Daily", expected_outcome: "Increased attention span and awareness of distraction patterns"},
      %{position: 2, purpose: "Pomodoro deep work sprints", steps: "25 minutes of uninterrupted work on one task. No email, no phone, no switching. 5-minute break. Repeat.", prescription: "Daily, 2-4 sprints", expected_outcome: "Dramatically increased deep work output"},
      %{position: 3, purpose: "Distraction audit", steps: "Track every time you get distracted for 1 day. Note: what triggered it, how long it lasted, what you were avoiding.", prescription: "Weekly audit day", expected_outcome: "Awareness of distraction patterns and targeted elimination"}
    ]
  },
  %{
    attrs: %{
      module_id: "PD0003",
      contributor: "Paula V",
      title: "Mental Reset Micro-Breaks",
      overview: "Quick reset sequences to clear mental fatigue and restore focus between tasks or meetings.",
      core_concepts: "1. The brain needs transitions between modes. 2. Micro-breaks prevent cumulative fatigue. 3. Physical movement resets cognitive state.",
      power_pillar_1: :power_down,
      module_type: :secondary,
      intensity: :low,
      daily_time: 10,
      weekly_freq: 5,
      daily_freq: 3,
      lead_time_fit: :short,
      experience_level: "Beginner",
      outcomes: "Sustained energy throughout the day. Reduced afternoon cognitive decline. Clearer thinking between meetings.",
      modifications: "Use seated versions if standing breaks aren't possible. 60-second version for time-constrained situations.",
      coach_tip: "Your brain wasn't designed for 8 hours of continuous output. Give it the breaks it needs and it will give you its best work.",
      coach_tip_attribution: "Paula V",
      outcome_keywords: ["Recovery", "Focus", "Energy"]
    },
    categories: ["Stress & Anxiety", "Life Force Reclamation"],
    protocols: [
      %{position: 1, purpose: "Physical micro-reset", steps: "Stand up. Roll shoulders 5x. Shake hands. Take 3 deep breaths. Sit back down.", prescription: "Between meetings, 3x daily minimum", expected_outcome: "Released physical tension and refreshed attention"},
      %{position: 2, purpose: "Visual reset", steps: "Look at something 20+ feet away for 20 seconds. Then close eyes for 20 seconds. Blink 5x.", prescription: "Every 60 minutes of screen time", expected_outcome: "Reduced eye strain and mental fatigue"},
      %{position: 3, purpose: "Cognitive transition", steps: "Before starting a new task, write one sentence: 'I am now focusing on ___.' Take 3 breaths. Begin.", prescription: "Between every task switch", expected_outcome: "Faster cognitive mode-switching and reduced residual thinking"}
    ]
  },

  # --- Andrea F (3 modules) ---
  %{
    attrs: %{
      module_id: "PU0002",
      contributor: "Andrea F",
      title: "Better Breakfasts",
      overview: "Transform your morning meal into a performance-optimizing ritual that fuels sustained energy, mental clarity, and hormonal balance.",
      core_concepts: "1. Breakfast sets metabolic tone for the day. 2. Protein and healthy fats stabilize blood sugar. 3. Front-loading nutrition prevents afternoon crashes.",
      power_pillar_1: :power_up,
      module_type: :foundational,
      intensity: :low,
      daily_time: 15,
      weekly_freq: 7,
      daily_freq: 1,
      lead_time_fit: :short,
      experience_level: "Beginner",
      time_to_result: "1 week",
      outcomes: "Stable energy through the morning. Reduced mid-morning cravings. Improved focus in morning meetings.",
      modifications: "Intermittent fasters can apply principles to first meal. Dairy-free and gluten-free alternatives available.",
      coach_tip: "Your breakfast is your first leadership decision of the day. Make it count. Protein first, always.",
      coach_tip_attribution: "Andrea F",
      outcome_keywords: ["Energy", "Nutrition", "Clarity"]
    },
    categories: ["Physical Vitality", "Life Force Reclamation"],
    protocols: [
      %{position: 1, purpose: "Protein-first breakfast", steps: "Aim for 25-30g protein at breakfast. Options: eggs + avocado, Greek yogurt + nuts, protein smoothie with greens.", prescription: "Daily", expected_outcome: "Stable blood sugar and sustained morning energy"},
      %{position: 2, purpose: "Eliminate blood sugar spikes", steps: "Remove or reduce refined carbs from breakfast (pastries, sweetened cereal, juice). Replace with complex carbs + protein.", prescription: "Daily", expected_outcome: "Eliminated mid-morning energy crashes"},
      %{position: 3, purpose: "Morning hydration ritual", steps: "Drink 500ml water within 30 minutes of waking, before coffee. Add lemon or electrolytes for absorption.", prescription: "Daily", expected_outcome: "Improved hydration and cognitive function"}
    ]
  },
  %{
    attrs: %{
      module_id: "PU0003",
      contributor: "Andrea F",
      title: "Anti-Inflammatory Eating",
      overview: "Adopt an anti-inflammatory dietary pattern to reduce chronic inflammation, support joint health, and optimize recovery.",
      core_concepts: "1. Chronic inflammation drives fatigue, pain, and cognitive fog. 2. Food is the most powerful anti-inflammatory tool. 3. Consistency matters more than perfection.",
      power_pillar_1: :power_up,
      power_pillar_2: :power_down,
      module_type: :secondary,
      intensity: :low,
      daily_time: 15,
      weekly_freq: 7,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Beginner",
      time_to_result: "2 weeks",
      outcomes: "Reduced joint pain and stiffness. Improved energy and reduced brain fog. Better sleep quality.",
      modifications: "Adapt for specific dietary restrictions. Introduce changes gradually over 2 weeks.",
      coach_tip: "Inflammation is invisible until it's not. What you eat today determines how you feel tomorrow. Start with one swap per day.",
      coach_tip_attribution: "Andrea F",
      outcome_keywords: ["Recovery", "Energy", "Health"]
    },
    categories: ["Physical Vitality", "Life Force Reclamation"],
    protocols: [
      %{position: 1, purpose: "Add anti-inflammatory foods daily", steps: "Include at least 2 servings of: fatty fish, leafy greens, berries, turmeric, or olive oil every day.", prescription: "Daily", expected_outcome: "Gradual reduction in systemic inflammation markers"},
      %{position: 2, purpose: "Reduce inflammatory triggers", steps: "Identify and reduce: processed sugar, refined seed oils, excessive alcohol. Track one trigger per week.", prescription: "Daily awareness", expected_outcome: "Fewer inflammation-related symptoms"},
      %{position: 3, purpose: "Anti-inflammatory meal planning", steps: "Plan 3 meals per week built around anti-inflammatory principles. Prep ingredients on Sunday.", prescription: "Weekly prep, daily execution", expected_outcome: "Consistent anti-inflammatory nutrition without daily decision fatigue"}
    ]
  },
  %{
    attrs: %{
      module_id: "PU0004",
      contributor: "Andrea F",
      title: "Eating for Cognitive Clarity",
      overview: "Optimize your nutrition specifically for brain performance — focus, memory, and mental endurance.",
      core_concepts: "1. The brain consumes 20% of daily calories. 2. Specific nutrients enhance neurotransmitter function. 3. Blood sugar stability is the foundation of mental clarity.",
      power_pillar_1: :power_up,
      module_type: :secondary,
      intensity: :low,
      daily_time: 15,
      weekly_freq: 7,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Intermediate",
      time_to_result: "2 weeks",
      outcomes: "Sharper focus during demanding cognitive work. Reduced brain fog and afternoon slumps. Better memory and recall.",
      modifications: "Supplement recommendations can replace food sources for those with restrictions.",
      coach_tip: "Feed your brain like you'd fuel a race car — premium fuel only. The quality of your thinking reflects the quality of what you eat.",
      coach_tip_attribution: "Andrea F",
      outcome_keywords: ["Focus", "Clarity", "Performance"]
    },
    categories: ["Critical Thinking", "Physical Vitality"],
    protocols: [
      %{position: 1, purpose: "Brain-fuel meals", steps: "Include omega-3 sources (salmon, walnuts, flax) and choline-rich foods (eggs, broccoli) daily.", prescription: "Daily", expected_outcome: "Enhanced neurotransmitter production and cognitive function"},
      %{position: 2, purpose: "Stabilize blood sugar for focus", steps: "Eat every 3-4 hours. Each meal: protein + healthy fat + complex carb. Avoid sugar spikes before important work.", prescription: "Daily", expected_outcome: "Consistent mental energy without crashes"},
      %{position: 3, purpose: "Strategic caffeine use", steps: "Delay coffee 90 minutes after waking. Limit to 2 cups before noon. Pair with L-theanine for calm focus.", prescription: "Daily", expected_outcome: "Optimized caffeine benefit without anxiety or crash"}
    ]
  },

  # --- Jenna M (3 modules) ---
  %{
    attrs: %{
      module_id: "PT0003",
      contributor: "Jenna M",
      title: "Walk with Command - Confidence in Heels",
      overview: "Master the physical mechanics of walking, standing, and moving with authority — including in heels — so your body language projects confidence before you say a word.",
      core_concepts: "1. How you move communicates before you speak. 2. Physical confidence is a trainable skill. 3. Balance and posture are the foundation of commanding presence.",
      power_pillar_1: :power_through,
      power_pillar_2: :empower,
      module_type: :secondary,
      intensity: :moderate,
      daily_time: 20,
      weekly_freq: 3,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Intermediate",
      outcomes: "Walk into any room with visible confidence. Maintain poise and balance in heels for extended periods. Project authority through movement alone.",
      modifications: "Practice barefoot first for balance foundation. Use block heels before stilettos. Seated posture alternatives for mobility limitations.",
      coach_tip: "Your walk is your opening statement. Before you open your mouth, your body has already told the room who you are. Train it to tell the right story.",
      coach_tip_attribution: "Jenna M",
      sources: "Biomechanics of gait and posture research; professional movement coaching methodologies",
      outcome_keywords: ["Confidence", "Presence", "Poise"]
    },
    categories: ["Commanding Presence", "Physical Vitality"],
    protocols: [
      %{position: 1, purpose: "Foundation posture drill", steps: "Stand with feet hip-width apart. Crown of head reaching up. Shoulders back and down. Engage core lightly. Hold 60 seconds.", prescription: "Daily, 3 sets", expected_outcome: "Improved baseline posture and body awareness"},
      %{position: 2, purpose: "Confident walk pattern", steps: "Walk a straight line, 10 steps. Lead with chest, land heel-to-toe, arms swinging naturally. Video yourself. Correct. Repeat.", prescription: "3x/week, 10 minutes", expected_outcome: "Natural, confident walking pattern"},
      %{position: 3, purpose: "Heel confidence progression", steps: "Start with 1-inch heels, practice walking and standing for 10 minutes. Progress to higher heels weekly. Focus on balance and fluidity.", prescription: "3x/week, progressive", expected_outcome: "Confident movement in heels without visible effort"},
      %{position: 4, purpose: "Room entry drill", steps: "Practice entering a room: pause at threshold, scan the room, walk to your destination with purpose. No phone, no looking down.", prescription: "Before events and meetings", expected_outcome: "Commanding room entries that establish presence immediately"}
    ]
  },
  %{
    attrs: %{
      module_id: "EM0003",
      contributor: "Jenna M",
      title: "Embodying Authority Without Saying a Word",
      overview: "Train the non-verbal signals that communicate authority, confidence, and leadership — posture, gestures, eye contact, and spatial awareness.",
      core_concepts: "1. 93% of communication is non-verbal. 2. Authority is projected through stillness, not movement. 3. Spatial awareness signals status.",
      power_pillar_1: :empower,
      power_pillar_2: :power_through,
      module_type: :foundational,
      intensity: :low,
      daily_time: 15,
      weekly_freq: 5,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Beginner",
      outcomes: "Project authority in meetings before speaking. Command attention through physical presence. Maintain composed body language under pressure.",
      modifications: "Seated authority adaptations for wheelchair users or those with mobility limitations.",
      coach_tip: "The most powerful person in the room is often the stillest. Stop fidgeting, plant your feet, and let your presence do the talking.",
      coach_tip_attribution: "Jenna M",
      sources: "Non-verbal communication research; executive presence coaching literature",
      outcome_keywords: ["Authority", "Presence", "Composure"]
    },
    categories: ["Commanding Presence", "Impact & Influence"],
    protocols: [
      %{position: 1, purpose: "Power posture holds", steps: "Stand or sit in an expansive posture: feet grounded, hands resting on table or at sides, chin level. Hold 2 minutes.", prescription: "Daily, before important interactions", expected_outcome: "Habitual authority posture that feels natural"},
      %{position: 2, purpose: "Eye contact training", steps: "In conversations, maintain eye contact for 3-5 seconds before looking away. Practice with a mirror, then in low-stakes conversations.", prescription: "Daily practice", expected_outcome: "Comfortable, confident eye contact that builds connection"},
      %{position: 3, purpose: "Gesture control", steps: "In your next meeting, keep hands below shoulder height. Use deliberate, purposeful gestures. Eliminate fidgeting.", prescription: "3x/week in meetings", expected_outcome: "Controlled, authoritative body language"},
      %{position: 4, purpose: "Spatial authority", steps: "In meetings, take up appropriate space: spread materials, use the full chair, don't shrink. In standing conversations, stand grounded.", prescription: "In every professional interaction", expected_outcome: "Physical presence that communicates status and confidence"}
    ]
  },
  %{
    attrs: %{
      module_id: "PT0004",
      contributor: "Jenna M",
      title: "Train with Intention, Perform with Precision",
      overview: "Transform your physical training from going through the motions to intentional, mind-body connected practice that builds both physical and mental performance.",
      core_concepts: "1. Mindless repetition builds nothing. 2. Mind-muscle connection multiplies training effect. 3. Intention transforms exercise into performance training.",
      power_pillar_1: :power_through,
      power_pillar_2: :power_up,
      module_type: :foundational,
      intensity: :moderate,
      daily_time: 20,
      weekly_freq: 3,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Beginner",
      outcomes: "More effective workouts in less time. Stronger mind-body connection. Reduced risk of injury through body awareness.",
      modifications: "Low-impact alternatives for joint issues. Seated versions for mobility limitations.",
      coach_tip: "Every rep is a conversation with your body. Are you listening? Train with intention and your body will perform with precision when it matters.",
      coach_tip_attribution: "Jenna M",
      sources: "Motor learning theory; mindful movement research; performance psychology",
      outcome_keywords: ["Strength", "Awareness", "Performance"]
    },
    categories: ["Physical Vitality", "Habit Mastery & Self-Discipline"],
    protocols: [
      %{position: 1, purpose: "Pre-training body scan", steps: "Before training, close eyes. Scan from head to toes. Note areas of tension, energy, or discomfort. Set one intention for the session.", prescription: "Before every training session", expected_outcome: "Enhanced body awareness and focused training"},
      %{position: 2, purpose: "Intentional movement practice", steps: "During each exercise, focus on the working muscle. Slow the movement 50%. Feel every phase. Quality over quantity.", prescription: "During training, 3x/week", expected_outcome: "Stronger mind-muscle connection and better training results"},
      %{position: 3, purpose: "Post-training reflection", steps: "After training, note: What did I notice? What felt strong? What needs attention? How did my intention play out?", prescription: "After every session", expected_outcome: "Continuous improvement and deepened body literacy"}
    ]
  },

  # --- Myra WIP Modules (11) ---
  %{
    attrs: %{
      module_id: "EM0004",
      contributor: "Myra",
      title: "Communicate with Impact",
      overview: "Master the art of purposeful communication — from clarity of message to emotional resonance — so your words move people to action, not just understanding.",
      core_concepts: "1. Clarity of intent precedes clarity of message. 2. Filler words dilute authority. 3. Reading your audience is a skill, not a talent.",
      power_pillar_1: :empower,
      power_pillar_2: :power_through,
      module_type: :foundational,
      intensity: :moderate,
      daily_time: 15,
      weekly_freq: 5,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Intermediate",
      outcomes: "Sharper, more purposeful delivery. Increased verbal precision and confidence. Higher engagement and message retention.",
      modifications: "Use voice memos instead of video for recording practice; start with low-stakes conversations.",
      coach_tip: "Impact isn't about volume or vocabulary — it's about intention. Know what you want before you open your mouth, say it with conviction, and then stop. The pause after your point lands is where influence lives.",
      coach_tip_attribution: "Myra",
      outcome_keywords: ["Communication", "Influence", "Clarity"]
    },
    categories: ["Impact & Influence", "Commanding Presence"],
    protocols: [
      %{position: 1, purpose: "Clarify your intent before speaking", steps: "Before any key communication, write one sentence answering: 'What do I want the listener to do, feel, or understand?' Align your opening statement to that intent.", prescription: "Before every meeting, presentation, or difficult conversation", expected_outcome: "Sharper, more purposeful delivery"},
      %{position: 2, purpose: "Eliminate filler and strengthen delivery", steps: "Record yourself delivering a 2-minute message; listen back noting filler words, pace, and clarity; re-deliver with corrections.", prescription: "2x/week", expected_outcome: "Increased verbal precision and confidence"},
      %{position: 3, purpose: "Read and adapt to your audience in real time", steps: "During conversations, pause every 3 minutes to check audience energy (body language, questions, engagement); adjust pace, tone, or content accordingly.", prescription: "In every key interaction", expected_outcome: "Higher engagement and message retention"}
    ]
  },
  %{
    attrs: %{
      module_id: "EM0005",
      contributor: "Myra",
      title: "Storytelling to Influence Decisions",
      overview: "Learn to craft and deliver stories that frame decisions, build alignment, and make your perspective unforgettable.",
      core_concepts: "1. Stories activate empathy and memory more than data alone. 2. A well-structured narrative frames the decision before the ask. 3. Personal stakes make abstract ideas concrete and urgent.",
      power_pillar_1: :empower,
      power_pillar_2: :power_up,
      module_type: :secondary,
      intensity: :low,
      daily_time: 15,
      weekly_freq: 3,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Beginner",
      outcomes: "Deliver a 90-second story that clearly frames a decision. Increase audience recall of your key message. Build alignment faster in group decision-making settings.",
      modifications: "Start with written stories before verbal delivery; use partner practice for feedback.",
      coach_tip: "Data convinces the mind, but stories move the heart. When you need people to act — not just agree — lead with a story that makes the stakes real.",
      coach_tip_attribution: "Myra",
      outcome_keywords: ["Storytelling", "Influence", "Persuasion"]
    },
    categories: ["Impact & Influence", "Commanding Presence"],
    protocols: [
      %{position: 1, purpose: "Build a personal story bank", steps: "Identify 5 professional moments where you made a difficult call or learned something unexpected; for each, write: the situation, the tension, the outcome, and the lesson.", prescription: "One-time exercise, revisit monthly", expected_outcome: "Ready-to-deploy stories for any context"},
      %{position: 2, purpose: "Structure stories for maximum impact", steps: "Use the Situation-Complication-Resolution framework; practice delivering one story in under 90 seconds; record and refine.", prescription: "2x/week", expected_outcome: "Tighter, more compelling narratives"},
      %{position: 3, purpose: "Deploy stories strategically", steps: "Before a key meeting, identify the decision at stake; select a story from your bank that frames the outcome you want; practice the transition from story to ask.", prescription: "Before high-stakes interactions", expected_outcome: "Decisions aligned with your perspective"}
    ]
  },
  %{
    attrs: %{
      module_id: "EM0006",
      contributor: "Myra",
      title: "Mobilize a Team",
      overview: "Rally your team around a shared mission by engaging all levels in problem-solving, removing barriers, and celebrating forward momentum.",
      core_concepts: "1. Teams mobilize around clarity of mission, not complexity of plans. 2. Servant leadership removes barriers and builds trust. 3. Recognition fuels sustained motivation.",
      power_pillar_1: :empower,
      power_pillar_2: :power_through,
      module_type: :foundational,
      intensity: :moderate,
      daily_time: 20,
      weekly_freq: 3,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Intermediate",
      outcomes: "Shared ownership and faster blocker resolution. Increased trust and team velocity. Sustained motivation and engagement.",
      modifications: "For remote teams, use async check-ins (Slack/email) with the same question framework.",
      coach_tip: "The best leaders don't have all the answers — they create the conditions for answers to emerge. Engage, empower, and get out of the way.",
      coach_tip_attribution: "Myra",
      outcome_keywords: ["Leadership", "Team", "Motivation"]
    },
    categories: ["Team Leadership", "Impact & Influence"],
    protocols: [
      %{position: 1, purpose: "Align the team to the mission", steps: "Open your next team meeting with one question: 'What is the one thing we need to achieve this week, and what's blocking it?' Listen without solving for 3 minutes. Then co-create the action plan.", prescription: "Weekly", expected_outcome: "Shared ownership and faster blocker resolution"},
      %{position: 2, purpose: "Practice servant leadership", steps: "Identify one barrier a team member is facing; remove it or escalate it within 24 hours; communicate back to the team what was done and why.", prescription: "2x/week", expected_outcome: "Increased trust and team velocity"},
      %{position: 3, purpose: "Celebrate incremental wins", steps: "End each week with a 5-minute recognition moment — name a specific win, the person behind it, and why it mattered.", prescription: "Weekly", expected_outcome: "Sustained motivation and engagement"}
    ]
  },
  %{
    attrs: %{
      module_id: "PD0004",
      contributor: "Myra",
      title: "Cool the Tension and Put People at Ease",
      overview: "De-escalate charged interactions and create psychological safety so productive dialogue can happen.",
      core_concepts: "1. Your calm is contagious — regulate yourself first and the room follows. 2. Validation disarms defensiveness faster than logic. 3. Pace and tone matter more than content in tense moments.",
      power_pillar_1: :power_down,
      power_pillar_2: :empower,
      module_type: :secondary,
      intensity: :moderate,
      daily_time: 10,
      weekly_freq: 3,
      daily_freq: 1,
      lead_time_fit: :short,
      experience_level: "Intermediate",
      outcomes: "Reduce visible tension in group interactions within 2 minutes. Increase team willingness to voice disagreements constructively. Maintain composure during conflict.",
      modifications: "Practice with low-stakes situations first; use written scripts before live delivery.",
      coach_tip: "Tension isn't the enemy — unmanaged tension is. Your ability to stay grounded when others can't is your superpower.",
      coach_tip_attribution: "Myra",
      outcome_keywords: ["De-escalation", "Calm", "Leadership"]
    },
    categories: ["Emotional Resilience", "Impact & Influence"],
    protocols: [
      %{position: 1, purpose: "Self-regulate before intervening", steps: "When tension rises, pause; take 3 slow breaths; soften your shoulders and jaw; lower your vocal tone by one notch.", prescription: "In every charged interaction", expected_outcome: "Faster return to productive dialogue"},
      %{position: 2, purpose: "Validate before redirecting", steps: "Name what you're hearing ('It sounds like this feels urgent/frustrating/unclear'); acknowledge it without agreeing or fixing; then redirect.", prescription: "In tense conversations", expected_outcome: "Reduced defensiveness, faster alignment"},
      %{position: 3, purpose: "Set the tone proactively", steps: "In meetings with known tension, open with a grounding statement ('I want us all to walk out of here aligned') and a process agreement.", prescription: "Before difficult meetings", expected_outcome: "Lower conflict intensity"}
    ]
  },
  %{
    attrs: %{
      module_id: "PT0005",
      contributor: "Myra",
      title: "Measured Reactions in Unexpected Situations",
      overview: "Train yourself to respond rather than react when blindsided, maintaining composure and credibility.",
      core_concepts: "1. The gap between stimulus and response is where power lives. 2. Reaction is instinct; response is training. 3. Post-event reflection accelerates growth.",
      power_pillar_1: :power_through,
      power_pillar_2: :empower,
      module_type: :foundational,
      intensity: :moderate,
      daily_time: 15,
      weekly_freq: 3,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Intermediate",
      outcomes: "Fewer reactive responses. Faster composure recovery. Continuous improvement in reactive patterns.",
      modifications: "Start with low-stakes simulations; use written reflection before verbal debriefs.",
      coach_tip: "The moment that catches you off guard is the moment that reveals your training. Don't react — respond.",
      coach_tip_attribution: "Myra",
      outcome_keywords: ["Composure", "Resilience", "Adaptability"]
    },
    categories: ["Emotional Resilience", "Stress & Anxiety"],
    protocols: [
      %{position: 1, purpose: "Create a response gap", steps: "When blindsided, use the 3-second rule — pause, take one breath, and ask a clarifying question before responding.", prescription: "In every unexpected situation", expected_outcome: "Fewer reactive responses"},
      %{position: 2, purpose: "Practice under simulation", steps: "Have a colleague deliver unexpected feedback or a curveball question during a practice session; apply the 3-second rule; debrief.", prescription: "2x/week", expected_outcome: "Faster composure recovery"},
      %{position: 3, purpose: "Post-event reflection", steps: "After an unexpected situation, journal: What happened? What did I feel? What did I do? What would I do differently?", prescription: "After each incident", expected_outcome: "Continuous improvement in reactive patterns"}
    ]
  },
  %{
    attrs: %{
      module_id: "EM0007",
      contributor: "Myra",
      title: "Make Decisions with Confidence",
      overview: "Build the muscle of decisive action by training yourself to gather sufficient (not perfect) information, commit fully, and course-correct without self-judgment.",
      core_concepts: "1. Decisiveness improves with practice, not with more data. 2. Good enough information, acted on quickly, beats perfect information acted on late. 3. Post-decision commitment matters more than pre-decision analysis.",
      power_pillar_1: :empower,
      power_pillar_2: :power_through,
      module_type: :foundational,
      intensity: :low,
      daily_time: 10,
      weekly_freq: 5,
      daily_freq: 3,
      lead_time_fit: :short,
      experience_level: "Beginner",
      outcomes: "Reduce decision time on recurring choices by 50%. Increase follow-through on decisions without second-guessing. Higher confidence in judgment calls under pressure.",
      modifications: "Start with decisions that have low consequences; build toward higher stakes gradually.",
      coach_tip: "Confidence doesn't come from being right every time — it comes from trusting yourself to handle whatever comes next. Decide, commit, adjust.",
      coach_tip_attribution: "Myra",
      outcome_keywords: ["Decisiveness", "Confidence", "Action"]
    },
    categories: ["Decision Making & Taking Action", "Critical Thinking"],
    protocols: [
      %{position: 1, purpose: "Train the decision muscle", steps: "For low-stakes daily decisions, set a 60-second timer; gather available information; decide; move on without revisiting.", prescription: "3x/day", expected_outcome: "Faster decision-making habit"},
      %{position: 2, purpose: "Apply the 70% rule", steps: "Before a key decision, list what you know vs. what you don't; if you have 70% of the information, decide now.", prescription: "For all medium/high-stakes decisions", expected_outcome: "Reduced analysis paralysis"},
      %{position: 3, purpose: "Build post-decision resilience", steps: "After a decision, journal: 'I chose X because Y. If it doesn't work, I will Z.' Refuse to revisit for 24 hours.", prescription: "After every significant decision", expected_outcome: "Reduced second-guessing"}
    ]
  },
  %{
    attrs: %{
      module_id: "EM0008",
      contributor: "Myra",
      title: "Increase Your Gravitational Pull with Colleagues",
      overview: "Build the kind of professional presence that draws people in — not through authority, but through reliability, curiosity, and genuine engagement.",
      core_concepts: "1. Influence is built through consistent micro-interactions. 2. Curiosity about others builds trust faster than expertise. 3. Following through creates magnetic credibility.",
      power_pillar_1: :empower,
      power_pillar_2: :power_up,
      module_type: :secondary,
      intensity: :low,
      daily_time: 10,
      weekly_freq: 5,
      daily_freq: 1,
      lead_time_fit: :long,
      experience_level: "Beginner",
      outcomes: "Be sought out for input on decisions outside your direct responsibility. Increase cross-functional collaboration invitations. Build a reputation as someone who delivers and elevates others.",
      modifications: "Start with one relationship or team; expand as the habit solidifies.",
      coach_tip: "Influence isn't about being the loudest voice — it's about being the one people trust. Show up curious, follow through relentlessly, and lift others as you rise.",
      coach_tip_attribution: "Myra",
      outcome_keywords: ["Influence", "Trust", "Relationships"]
    },
    categories: ["Impact & Influence", "Commanding Presence"],
    protocols: [
      %{position: 1, purpose: "Build the curiosity habit", steps: "In every meeting or 1:1, ask one genuine question about the other person's challenge before sharing your own. Listen fully.", prescription: "Daily", expected_outcome: "Deeper professional relationships"},
      %{position: 2, purpose: "Close every loop", steps: "Track every commitment you make in a day; close each one within 24 hours or proactively communicate a new timeline.", prescription: "Daily", expected_outcome: "Reputation as someone who delivers"},
      %{position: 3, purpose: "Elevate others publicly", steps: "In group settings, name a colleague's contribution before adding your own ('Building on what [name] said...').", prescription: "In every group interaction", expected_outcome: "Increased trust and reciprocal support"}
    ]
  },
  %{
    attrs: %{
      module_id: "PD0005",
      contributor: "Myra",
      title: "Focus on What Matters Most",
      overview: "Cut through noise, competing priorities, and urgency bias to identify and protect the work that actually moves the needle.",
      core_concepts: "1. Urgency and importance are not the same thing. 2. Saying no to good things is required to say yes to great things. 3. Daily intention-setting prevents reactive spiraling.",
      power_pillar_1: :power_down,
      power_pillar_2: :empower,
      module_type: :foundational,
      intensity: :low,
      daily_time: 15,
      weekly_freq: 5,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Beginner",
      outcomes: "Identify the single highest-leverage task each day. Reduce time spent on reactive work by 25%. Greater sense of progress on meaningful goals.",
      modifications: "Use a physical notebook if digital tools create distraction; pair with a weekly review.",
      coach_tip: "Busy is not productive. The most powerful leaders aren't the ones doing the most — they're the ones doing the right things.",
      coach_tip_attribution: "Myra",
      outcome_keywords: ["Focus", "Prioritization", "Productivity"]
    },
    categories: ["Prioritization & Time Mngmt.", "Critical Thinking"],
    protocols: [
      %{position: 1, purpose: "Set the day's anchor", steps: "Before opening email/Slack, write: 'The one thing that matters most today is ___.' Protect the first 90 minutes for that task.", prescription: "Daily", expected_outcome: "Consistent progress on high-value work"},
      %{position: 2, purpose: "Audit your time", steps: "At the end of each day, categorize your time: strategic, reactive, or maintenance. Aim for 40%+ strategic.", prescription: "Daily, 5 minutes", expected_outcome: "Awareness of time allocation patterns"},
      %{position: 3, purpose: "Practice strategic no", steps: "When a new request arrives, ask: 'Does this serve my top priority this week?' If no, defer, delegate, or decline.", prescription: "As needed", expected_outcome: "Protected focus time"}
    ]
  },
  %{
    attrs: %{
      module_id: "EM0009",
      contributor: "TBD",
      title: "Build Your Personal Brand",
      overview: "Define and project a professional identity that is authentic, memorable, and strategically aligned to your goals.",
      core_concepts: "1. Your brand is what people say about you when you're not in the room. 2. Consistency across channels builds recognition and trust. 3. Authenticity is more compelling than polish.",
      power_pillar_1: :empower,
      power_pillar_2: :power_up,
      module_type: :secondary,
      intensity: :low,
      daily_time: 15,
      weekly_freq: 3,
      daily_freq: 1,
      lead_time_fit: :long,
      experience_level: "Beginner",
      outcomes: "Articulate your professional value proposition in one clear sentence. Increase visibility in your industry or organization. Feedback that your external presence matches your internal intent.",
      modifications: "Start with internal visibility before external; use written formats if speaking feels high-stakes.",
      coach_tip: "Your brand isn't your title or your resume — it's the feeling people have after interacting with you. Be intentional about that feeling.",
      coach_tip_attribution: "TBD",
      outcome_keywords: ["Brand", "Visibility", "Authenticity"]
    },
    categories: ["Impact & Influence", "Commanding Presence"],
    protocols: [
      %{position: 1, purpose: "Define your core message", steps: "Answer: 'What do I want to be known for? What problem do I solve? Who needs to know?' Write a 1-sentence positioning statement.", prescription: "One-time exercise, revisit quarterly", expected_outcome: "Clear, deployable self-description"},
      %{position: 2, purpose: "Audit your digital presence", steps: "Review LinkedIn, email signature, and public profiles; ensure alignment with your positioning statement; update one element per week.", prescription: "Weekly for 4 weeks", expected_outcome: "Consistent external presence"},
      %{position: 3, purpose: "Create visibility moments", steps: "Identify one opportunity per week to share your perspective publicly (comment, speak up in a meeting, share an insight).", prescription: "Weekly", expected_outcome: "Increased recognition in your domain"}
    ]
  },
  %{
    attrs: %{
      module_id: "EM0010",
      contributor: "Myra",
      title: "Control the Conversation",
      overview: "Steer conversations toward productive outcomes by setting frames, bridging off-track discussions, and closing with clear commitments.",
      core_concepts: "1. Conversation control is about direction, not domination. 2. Bridging phrases redirect without resistance. 3. Closing with commitment creates accountability.",
      power_pillar_1: :empower,
      power_pillar_2: :power_through,
      module_type: :secondary,
      intensity: :moderate,
      daily_time: 15,
      weekly_freq: 3,
      daily_freq: 1,
      lead_time_fit: :medium,
      experience_level: "Intermediate",
      outcomes: "Conversations that reach your intended outcome. Smooth redirection without resistance. Clear accountability and follow-through.",
      modifications: "Use written agendas as training wheels; practice bridging with a partner first.",
      coach_tip: "Controlling a conversation isn't about talking more — it's about knowing where it needs to go and steering with precision.",
      coach_tip_attribution: "Myra",
      outcome_keywords: ["Communication", "Leadership", "Strategy"]
    },
    categories: ["Impact & Influence", "Decision Making & Taking Action"],
    protocols: [
      %{position: 1, purpose: "Set the frame before the conversation starts", steps: "Before key meetings, write your objective in one sentence; open with it; revisit it if the conversation drifts.", prescription: "Before every important meeting", expected_outcome: "Conversations that reach your intended outcome"},
      %{position: 2, purpose: "Master the bridge", steps: "When the conversation veers off track, use: 'That's an important point — and it connects to what we need to decide about [your topic].'", prescription: "3x/week", expected_outcome: "Smooth redirection without resistance"},
      %{position: 3, purpose: "Close with commitment", steps: "In the final 2 minutes: 'Here's what I heard us agree on...' and assign next steps with names and dates.", prescription: "Every conversation", expected_outcome: "Clear accountability and follow-through"}
    ]
  },
  %{
    attrs: %{
      module_id: "PD0006",
      contributor: "Myra",
      title: "Trust Your Interpersonal Instincts",
      overview: "Develop confidence in your ability to read people, situations, and dynamics — and act on that read.",
      core_concepts: "1. Intuition is pattern recognition built from experience. 2. Emotional data is real data. 3. The gap between sensing something and acting on it is where courage lives.",
      power_pillar_1: :power_down,
      power_pillar_2: :empower,
      module_type: :secondary,
      intensity: :moderate,
      daily_time: 15,
      weekly_freq: 5,
      daily_freq: 1,
      lead_time_fit: :long,
      experience_level: "Intermediate",
      outcomes: "Increase confidence in reading interpersonal dynamics. Act on gut instinct more quickly in professional settings. Fewer instances of 'I knew I should have said something.'",
      modifications: "Start with low-stakes social situations; build toward professional high-stakes.",
      coach_tip: "Your instincts have been trained by every interaction you've ever had. Stop second-guessing them.",
      coach_tip_attribution: "Myra",
      outcome_keywords: ["Intuition", "Confidence", "Awareness"]
    },
    categories: ["Emotional Resilience", "Impact & Influence"],
    protocols: [
      %{position: 1, purpose: "Build awareness of your signals", steps: "After key interactions, journal: 'What did I sense? What did I do with that information? What would I do differently?'", prescription: "Daily", expected_outcome: "Stronger connection between intuition and action"},
      %{position: 2, purpose: "Practice acting on reads", steps: "In your next 3 interactions, identify one moment where you sense something unspoken; name it gently.", prescription: "3x/week", expected_outcome: "Validated instincts and deeper conversations"},
      %{position: 3, purpose: "Distinguish intuition from anxiety", steps: "When you have a strong gut feeling, pause and ask: 'Is this pattern recognition or fear?' If pattern recognition, act. If fear, breathe and reassess.", prescription: "As needed", expected_outcome: "More accurate reads and fewer false alarms"}
    ]
  }
]

for module_data <- modules_data do
  case Repo.get_by(Module, module_id: module_data.attrs.module_id) do
    nil ->
      categories = find_categories.(module_data.categories)

      {:ok, module} =
        Modules.create_module_with_categories(module_data.attrs, categories)

      for protocol_attrs <- module_data[:protocols] || [] do
        Modules.create_protocol(Map.put(protocol_attrs, :module_id, module.id))
      end

      IO.puts("  Created: #{module.title} (#{module.module_id})")

    existing ->
      IO.puts("  Exists:  #{existing.title} (#{existing.module_id})")
  end
end

IO.puts("\n=== Module Library Seeding Complete ===")
IO.puts("Goal Categories: #{Repo.aggregate(GoalCategory, :count)}")
IO.puts("Modules: #{Repo.aggregate(Module, :count)}")
IO.puts("Protocols: #{Repo.aggregate(SheCommands.Modules.Protocol, :count)}")
