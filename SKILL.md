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

Turn a GitHub PR link into a standards-based review with actionable feedback. When issues are
found the review **requests changes** (`REQUEST_CHANGES`) so the PR is blocked from merging
until the author addresses them. Clean PRs get an `APPROVE`.

## 0. Preconditions

- **Auth:** The GitHub token is auto-loaded from `~/.claude/.github_token` (set up by `install.bat`).
  If the token is missing or expired, the scripts will show an error — run `install.bat` from the
  osos-code-review repo to set up or refresh the token.
- **Tooling:** `curl` and `jq` must be present (the scripts use them).
- **Install:** Clone the repo and run `install.bat`. It copies files to `~/.claude/` and saves the token.
- Scripts live in `~/.claude/scripts/`. Reference rules live in `~/.claude/references/`.

## 1. Parse the PR URL

From a URL like `https://github.com/<owner>/<repo>/pull/<number>` extract `owner`, `repo`,
`number`. Also accept the shorthand `<owner>/<repo>#<number>`. If you can't get all three, ask.

## 2. Fetch the PR

```bash
bash $HOME/.claude/scripts/fetch_pr.sh <owner> <repo> <number>
```

Output has three sections: `===META===` (title, body, author, head_sha, base/head refs, counts),
`===DIFF===` (full unified diff), `===FILES===` (JSON array of `{path,status,additions,deletions,patch}`).
Read all three. If the script errors (401/404), relay the message and stop.

## 3. Load only the relevant rulebooks

All rules are in `~/.claude/references/`. Load by what the diff actually touches — don't load everything by reflex:

| If the PR touches… | Load |
|---|---|
| any `.cs` file (almost always) | `naming-style.md`, `architecture-cqrs.md` (includes `BaseHandler` / `IHttpContextAccessor` rules) |
| repositories, `DbContext`, `SaveChanges`, transactions, EF queries, loops over data, audit fields (`CreatedBy`, `CreateDate`, etc.), JSON columns / `jsonb` / `[JsonColumn]` | `data-transactions-perf.md` |
| `try/catch`, exceptions, logging, `Console.WriteLine` | `error-logging.md` |
| endpoints, `Program.cs`/startup, auth, `*Behavior`, validators, secrets, raw SQL | `security-auth-pipelines.md` |
| validators, tests, or reviewing PR scope/commits | `testing-vcs.md` |

When unsure, load more rather than fewer. Read the files with the `view` tool before judging.

## 4. Review the diff

Go through each changed hunk and check it against the loaded rules. For every real issue produce a finding:

- **severity** — 🔴 Blocker (correctness/security/data-integrity: e.g. TX-2 no rollback, SEC-2 SQL injection, NET-2 `.Result`, ARCH-Q2 mixed read/write), 🟡 Should-fix (violates a standard, works but wrong), 🔵 Nit (style/naming).
- **file + line** — the line **in the new file** (RIGHT side of the diff). Inline comments may ONLY target lines that appear as added/changed context in the PR's diff. If an issue is about something not on a diff line (missing test, PR scope, a whole-file concern), put it in the summary instead, not inline.
- **rule id** — cite it (e.g. `TX-2`, `NAME-C2`) so the author can look it up.
- **why + fix** — one or two sentences, constructive, with the corrected snippet when short.

Discipline that keeps this trustworthy:
- **Precision over volume.** Only flag things you're confident about from the diff. You see a partial file; if a call *might* be fine given code outside the diff, say "if X isn't handled elsewhere…" or skip it. False positives on a junior's PR erode trust fast.
- **Group repeats.** If the same nit appears 10 times, make one inline comment on the first and note "same applies elsewhere" — don't spam.
- **Blockers are rare.** Reserve 🔴 for genuine correctness/security/data-loss issues.
- **Be kind and specific.** The team's own standard says give *constructive* feedback. No scolding; explain the why.

## 5. Show the reviewer first — never post silently

Present the findings in chat, grouped by severity, each as `severity [rule] file:line — issue → fix`.
Then propose a short summary verdict (e.g. "2 blockers, 3 should-fix, 4 nits — recommend changes before merge"
or "looks clean, minor nits only"). Then ask how to proceed:

- **Post everything** (inline comments + summary), or
- **Post selected** (they name which), or
- **Summary only** (one comment, no inline), or
- **Don't post** (they'll act on it themselves).

Default to waiting for their choice. Do not post without an explicit go-ahead.

## 6. Post (only after approval)

**Inline + summary** → build a GitHub review payload and post it.

Pick the `event` based on findings:

| Findings | `event` |
|---|---|
| Any 🔴 Blocker **or** 🟡 Should-fix | `REQUEST_CHANGES` — blocks the PR until resolved |
| Only 🔵 Nits (or none) | `APPROVE` — approves with optional nit comments |

```jsonc
// /tmp/osos_review.json
{
  "event": "REQUEST_CHANGES",      // or "APPROVE" — see table above
  "body": "### OSOS standards review\n\n**Summary:** …\n\n🔴 Blockers: N  🟡 Should-fix: N  🔵 Nits: N\n\n<anything not anchorable inline>",
  "comments": [
    { "path": "Modules/Lnd/Lnd.Application/PathwayService.cs", "line": 42, "side": "RIGHT",
      "body": "🟡 **[NAME-C2]** Private field should be camelCase without a leading underscore.\n```csharp\nprivate readonly string studentName;\n```" }
  ]
}
```

```bash
bash $HOME/.claude/scripts/post_review.sh <owner> <repo> <number> /tmp/osos_review.json
```

If GitHub rejects a comment for targeting a line not in the diff, move that finding into `body` and retry.

**Summary only** → write the markdown to a file and:

```bash
bash $HOME/.claude/scripts/post_comment.sh <owner> <repo> <number> /tmp/osos_summary.md
```

Report the posted comment/review URL back to the reviewer.

## Comment style template

Keep each inline comment tight:

> {severity} **[{RULE-ID}]** {one-line problem}. {optional: why it matters in one clause}.
> ```csharp
> {short corrected snippet, if helpful}
> ```

Summary body should open with the verdict, then the severity counts, then any non-inline notes
(missing tests, PR scope/commit hygiene, cross-file concerns). Keep it scannable.

## Scope notes

- Backend-focused (.NET/C#/EF Core/PostgreSQL). If a PR is mostly Angular/frontend, say so and
  review only what these rules cover.
- You review the diff, not the whole repo — call out when a proper judgement would need more context.
- When blockers or should-fix issues are found, the review uses `REQUEST_CHANGES` to block the PR from merging until addressed.
