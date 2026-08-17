---
name: osos-code-review
description: >-
  Review a GitHub pull request against the OSOS ERP company code-review standards
  (.NET 8/9, C# 12, modular CQRS/MediatR, EF Core, PostgreSQL) and leave constructive
  review comments. Use this whenever someone pastes a GitHub PR URL and asks to review
  it, check it, or comment on it — e.g. "review this PR", "check https://github.com/pbsgears/ososerp/pull/123",
  "any issues in this PR?", or invokes /review-pr. Handles fetching the diff, applying the
  team's naming, architecture, transaction, security, error-handling, testing, and version-control
  rules, and posting inline + summary comments back to the PR. Trigger it even when the person
  just drops a pbsgears/ososerp (or any GitHub) pull-request link with intent to review.
---

# OSOS Code Review

PR review against OSOS standards. Issues → `REQUEST_CHANGES` (blocks merge). Clean → `APPROVE`.

## 0. Preconditions

- **Auth:** Auto-loaded from `~/.claude/.github_token`. If missing/expired, run `install.bat`.
- **Tooling:** `curl`, `jq` required.
- **Model:** Detailed rules ship with this skill — use `/model sonnet` or `/model haiku` to save cost.
- **Paths:** Scripts: `~/.claude/skills/osos-code-review/scripts/` | Rules: `~/.claude/skills/osos-code-review/references/`

## 1. Parse the PR URL

Extract `owner`, `repo`, `number` from `https://github.com/<owner>/<repo>/pull/<number>` or `<owner>/<repo>#<number>`. If unclear, ask.

## 2. Fetch the PR

```bash
bash $HOME/.claude/skills/osos-code-review/scripts/fetch_pr.sh <owner> <repo> <number>
```

Returns `===META===` (JSON), `===DIFF===` (unified diff), `===FILES===` (file list with add/delete counts). Read all three. On error (401/404), relay and stop.

## 3. Load only the relevant rulebooks

All rules are in `~/.claude/skills/osos-code-review/references/`. Load by what the diff actually touches — don't load everything by reflex:

| If the PR touches… | Load |
|---|---|
| any `.cs` file (almost always) | `naming-style.md`, `architecture-cqrs.md` (includes `BaseHandler` / `IHttpContextAccessor` rules) |
| repositories, `DbContext`, `SaveChanges`, transactions, EF queries, loops over data, audit fields (`CreatedBy`, `CreateDate`, etc.), JSON columns / `jsonb` / `[JsonColumn]` | `data-transactions-perf.md` |
| `try/catch`, exceptions, logging, `Console.WriteLine` | `error-logging.md` |
| endpoints, `Program.cs`/startup, auth, `*Behavior`, validators, secrets, raw SQL | `security-auth-pipelines.md` |
| validators, tests, or reviewing PR scope/commits | `testing-vcs.md` |

When unsure, load more rather than fewer. Read the files with the `view` tool before judging.

## 4. Review the diff

Check each hunk against loaded rules. Per finding:

- **severity** — 🔴 Blocker (correctness/security/data-loss), 🟡 Should-fix (violates standard), 🔵 Nit (style).
- **file + line** — RIGHT side of diff only. Non-diff concerns (missing test, PR scope) go in summary, not inline.
- **rule id** — cite it (e.g. `TX-2`, `NAME-C2`).
- **why + fix** — 1-2 sentences, constructive, with corrected snippet when short.

Discipline:
- **Precision over volume.** Only flag what you're confident about. Partial file → "if X isn't handled elsewhere…" or skip. False positives erode trust.
- **Group repeats.** Same nit 10 times → one inline comment + "same applies elsewhere".
- **Blockers are rare.** Reserve 🔴 for genuine correctness/security/data-loss.
- **Be kind.** Constructive feedback, no scolding.

## 5. Show the reviewer first — never post silently

Present findings grouped by severity: `severity [rule] file:line — issue → fix`.
Propose a verdict, then ask: **Post everything** / **Post selected** / **Summary only** / **Don't post**.
Do not post without explicit go-ahead.

## 6. Post (only after approval)

**event:** Any 🔴/🟡 → `REQUEST_CHANGES` | Only 🔵/none → `APPROVE`

Write `/tmp/osos_review.json` with `{ event, body, comments: [{ path, line, side:"RIGHT", body }] }`.

```bash
bash $HOME/.claude/skills/osos-code-review/scripts/post_review.sh <owner> <repo> <number> /tmp/osos_review.json
```

If GitHub rejects a line target, move that finding into `body` and retry.

**Summary only** → write markdown to file:

```bash
bash $HOME/.claude/skills/osos-code-review/scripts/post_comment.sh <owner> <repo> <number> /tmp/osos_summary.md
```

Report the posted URL back.

## 7. Re-review (follow-up after fixes)

Triggered by "re-review", "re-check", "verify fixes" on a previously reviewed PR.

**7a.** Fetch current diff + previous comments (run in parallel):

```bash
bash $HOME/.claude/skills/osos-code-review/scripts/fetch_pr.sh <owner> <repo> <number>
bash $HOME/.claude/skills/osos-code-review/scripts/fetch_review_comments.sh <owner> <repo> <number>
```

**7b.** For each prior `REQUEST_CHANGES` inline comment, check the current diff:
- **Resolved** — issue fixed correctly
- **Partially addressed** — attempted but incomplete or introduced new issue
- **Not addressed** — unchanged or same problem remains

Flag any new issues from the fixes (same format as step 4).

**7c.** Present a status table, then verdict:
- All resolved + no new issues → `APPROVE`
- Any unresolved or new → `REQUEST_CHANGES`

Ask before posting (same as step 5). Summary body should say "Follow-up review" with resolved/unresolved/new counts.

## Comment style

Inline: `{severity} **[{RULE-ID}]** {problem}. {why}. {corrected snippet if short}`
Summary: verdict → severity counts → non-inline notes. Keep scannable.

## Scope

- Backend only (.NET/C#/EF Core/PostgreSQL). Frontend PRs → say so, review only what rules cover.
- Review the diff, not the whole repo — call out when more context is needed.
