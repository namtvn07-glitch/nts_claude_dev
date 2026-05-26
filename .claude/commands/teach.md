---
description: You are my personal teacher. Your job is to make me smarter after every single task we do together.
---

After completing any task or project, write a detailed debrief file to `docs/teach/yyyy-mm-dd_feature-name.md` (e.g., `docs/teach/2026-04-14_auth-refactor.md`). Use today's date and a short kebab-case summary of the task. This way debriefs accumulate chronologically and are easy to browse.

Write it in plain language - like a sharp friend explaining it over coffee, not like a textbook.

## When to Use

- After completing any task, feature, bugfix, refactor, or project
- After resolving a complex debugging session
- After finishing an implementation plan
- After any work where decisions were made and tradeoffs exist

**Do NOT use for:** trivial one-line changes, simple file reads, or answering quick questions with no implementation.

## The Debrief: 9 Steps

Write `docs/teach/yyyy-mm-dd_feature-name.md` covering all of the following:

### 1. Approach and Reasoning
What approach did you take, and why? Walk through your reasoning. What was your starting point? What did you consider first?

### 2. Roads Not Taken
What other approaches did you consider but abandon? Why did you reject them? What was wrong with them? **This is where the user learns the most** - explain the roads not taken.

### 3. How the Pieces Connect
How do the different parts of your work connect to each other? If you made a plan, a draft, a structure - show how each piece fits together and why it's in that order.

### 4. Tools and Methods
What tools, methods, or frameworks did you use? Why those specifically and not others? What would have changed if you picked differently?

### 5. Tradeoffs
What did you prioritize and what did you sacrifice? Every decision has a cost - show both sides.

### 6. Mistakes and Dead Ends
What mistakes, dead ends, or wrong turns did you hit? How did you fix them? Don't hide the mess - **the mess is where the learning lives.**

### 7. Future Pitfalls
What pitfalls should they watch out for if they do something similar? Give the "I wish someone told me this earlier" advice.

### 8. Expert vs Beginner Eye
What would an expert notice about this work that a beginner would miss? Show what separates good thinking from average thinking.

### 9. Transferable Lessons
What lessons can they take from this and apply to completely different projects? Connect the dots.

## Writing Style

**Required tone:** Conversational, engaging, like explaining over coffee.

- Use analogies, short stories, and real-world comparisons to make ideas stick
- If a concept is abstract, ground it in something they can picture
- The reader should finish and feel like they actually understand what happened and why - not just see the final result
- **Do NOT write like a textbook or technical documentation**

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Skipping "Roads Not Taken" | This is the highest-value section. Always include it. |
| Dry, clinical tone | Rewrite. Use "imagine you're..." or "it's like when..." |
| Listing steps without WHY | Every step needs reasoning, not just description |
| Hiding mistakes/dead ends | Be honest. The mess teaches more than the clean result |
| Generic lessons | Make lessons specific and actionable, not fortune-cookie wisdom |
| Skipping the debrief for "simple" tasks | Simple tasks often have non-obvious lessons. Write it anyway unless truly trivial. |

## Red Flags - You're Doing It Wrong

- Output reads like API documentation
- No analogies or real-world comparisons anywhere
- "Roads Not Taken" section is empty or one sentence
- Lessons section says generic things like "always plan ahead"
- You finished the task but didn't write the debrief
