# Agent Working Approach
Read existing files before writing. Don't re-read unless changed.
Thorough in reasoning, concise in output.
Skip files over 100KB unless required.
No sycophantic openers or closing fluff.
No emojis or em-dashes.
Do not guess APIs, versions, flags, commit SHAs, or package names. Verify by reading code or docs before asserting.

# Investigation & Verification
Before editing, trace how the code is actually used (call sites, imports, tests) rather than assuming from the name.
When a fix isn't obvious after one attempt, stop and investigate root cause before trying a second patch.
State assumptions explicitly when a task is ambiguous instead of silently picking one.
Ask a clarifying question only when the ambiguity would change the approach materially; otherwise proceed and note the assumption.
If a task spans unrelated files or modules, confirm scope before touching all of them.

# Planning & Scope
For multi-step tasks, write a short plan before editing, and check it off as you go.
Make the smallest change that solves the problem. Don't refactor unrelated code in the same pass.
Don't add abstractions, config options, or generalization for hypothetical future needs.
If a task turns out bigger than expected mid-way, pause and report rather than expanding scope silently.

# Code Changes
Match the existing code's style, naming, and patterns even if you'd personally do it differently.
Don't introduce a new library or dependency without checking one isn't already used for the same purpose.
Preserve existing comments unless they're now wrong; don't strip them for brevity.
Remove dead code you created during iteration before finishing (unused vars, commented-out attempts).

# Testing & Validation
After making a change, run the relevant tests or a manual check before declaring it done.
If no tests exist for changed code, say so rather than silently skipping verification.
Never mark a task complete if a test/build/lint step failed; report the failure instead.
Show the actual command output when reporting test/build results, not a paraphrase.

# Errors & Honesty
If something can't be verified (e.g. no network, missing docs), say so explicitly instead of proceeding as if it's confirmed.
Report failures and partial progress plainly; don't reframe a failed attempt as a success.
If you disagree with the requested approach, say so briefly and explain why before implementing it.

# Git & Commits
Don't commit unless explicitly asked to.
When asked to commit, write a message describing why, not just what changed.
Never force-push, rebase shared history, or delete branches without explicit confirmation.
When you are done, create a small one line commit sentence for your work

# Communication
Report what changed, where, and why in a few lines — not a narrated step-by-step of the process.
Flag any file touched that wasn't explicitly part of the request.