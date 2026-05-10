---
name: review-mr
description: Procedure and rubric for reviewing a GitLab merge request — what to check, how to prioritize, how to format inline comments. Use whenever reviewing an MR, whether invoked directly or via the mr-reviewer agent.
---

# Reviewing a GitLab merge request

This skill defines *how* we review. The GitLab MCP tools (prefix `mcp__gitlab__`) are the mechanism; this document is the judgment.

## Phase 1 — Orient

Before reading a single line of diff:

1. Read the MR title, description, and linked issue (as Notion task ID of the form `<PREFIX>-<NUMBER>` (e.g. `DS-123`)). If the description is empty or just "see title", note that — you'll mention it in the summary. If there is no mention of a Notion task in the MR description, try to determine it from the title or the branch name. The convention is that the branch names and MR titles are prefixed with the Notion task ID, so if you see `DS-123` in the title or branch, that's a strong signal. If you can't find any ID, note that too — it may be relevant to the review quality and is worth mentioning in the summary.
2. Check the pipeline status. If CI is failing, that's context: either the author knows and is iterating, or they don't, in which case a top-level note pointing at the failing job is more useful than 20 inline nits.
3. Skim the list of changed files. Group them mentally: core logic, tests, config, generated/vendored. Generated files get skipped. Tests get read *with* the code they test.
4. Read the full diff once, end-to-end, without commenting. Build a model of what the change is *trying* to do. Only then start the real pass.
5. If the MR links to a Notion task (see the `fetch-notion-task` skill), check how the contribution fits the generic task description. If the MR has no link to Notion UUID, skip this phase, otherwise write your judgement as a generic comment to the merge request.


## Phase 2 — Review, in priority order

Comment on things in roughly this order of importance. Stop when you've said what matters; do not manufacture comments to look thorough.

1. **Acceptance criteria.** If the MR links to a Notion task (see the `fetch-notion-task` skill), check each code-verifiable criterion against the diff. For each: is it implemented, partially implemented, or missing? Post a `[blocking]` comment for missing criteria, a `[question]` for partial ones. Skip criteria that can't be judged from code (performance, UX, infra) — mention in the top-level summary that they weren't verified. If the MR has no link to Notion UUID, skip this phase and note it in the summary.
2. **Correctness.** Does the code do what the description claims? Off-by-one, wrong branch taken, missed error path, race condition, resource leak, incorrect SQL, wrong units. This is the only category where you should be confident and direct.
3. **Security.** Injection, unvalidated input crossing a trust boundary, secrets in code or logs, auth/authz bypass, unsafe deserialization. Be specific about the threat, not generic ("this is unsafe").
4. **Data & migration safety.** Schema changes, backfills, destructive operations, anything touching prod data. Ask about rollback, concurrent-write behavior, and whether the change is reversible.
5. **API / interface changes.** Breaking changes, renamed fields, changed defaults. Who else depends on this? Is there a deprecation path?
6. **Test coverage of the change itself.** Not "coverage percentage" — does at least one test *fail* if the new logic is wrong? A passing test that would also pass with the code deleted is not coverage.
7. **Clarity.** Names that mislead, control flow that hides intent, a 60-line function that wants to be three. Only flag when it will actually bite a future reader — not as taste.
8. **Consistency with the surrounding codebase.** Use Read/Grep to check how similar things are done elsewhere before asserting "this is wrong here."

Explicitly **do not** comment on:
- Formatting, import order, trailing whitespace — linter's job.
- Personal style preferences that aren't codified in the project.
- Hypothetical future requirements ("what if we need X someday").
- Things the author clearly already considered (look for a comment, a test, or the commit message addressing it before objecting).

## Phase 3 — Comment format

Each inline comment has a severity tag so the author can triage fast:

- **`[blocking]`** — must change before merge. Correctness, security, data safety.
- **`[suggest]`** — should probably change, but the author can justify not changing. Clarity, minor design.
- **`[question]`** — you don't understand why it's done this way; the answer might be "good reason" or might reveal a bug.
- **`[nit]`** — trivial, take it or leave it. Use sparingly. If you have more than two nits, you're reviewing the wrong things.

Body of the comment:

1. One sentence stating the problem.
2. One sentence on *why* it matters (the specific failure mode, not "best practice").
3. Optionally, one concrete suggestion. Don't paste a rewritten block unless it's under ~5 lines.

Example:
> `[blocking]` This retries on any exception, including `KeyboardInterrupt` and `SystemExit`. On Ctrl-C the worker will loop forever instead of exiting. Catch `Exception` instead of bare `except:`.

## Phase 4 — Summarize

Post one top-level note on the MR with: overall verdict, how does the contribution correspond to the generic task description, count of blocking issues, and anything systemic you noticed that didn't fit in an inline comment (missing tests for the feature as a whole, description gaps, CI failing for an unrelated reason, etc.).

Besides posting the summary as a comment on GitLab, return the structured summary to the caller in the format the `mr-reviewer` agent specifies.

## GitLab-specific notes

- Inline comments on a diff require a **position** object (base SHA, head SHA, start SHA, file paths, line numbers). The MCP tool for creating a discussion handles this; make sure you pass the *new* line for added lines and the *old* line for removed lines. Mis-positioned comments are the most common failure mode.
- If the MR has been force-pushed since you fetched the diff, your positions may be stale. Re-fetch before posting if the review took a while.
- Use `create_merge_request_discussion` (threaded, resolvable) rather than `create_merge_request_note` (flat) for review feedback, so the author can resolve each thread as they address it.
