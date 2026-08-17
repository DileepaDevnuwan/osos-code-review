# Testing, Validation & Version Control (rule prefix: TEST / VCS)

Source: Testing & Validation, Version Control & Merge Quality.

## Validation & Tests (TEST)
- **TEST-1** 🔴 Commands are validated with FluentValidation (`AbstractValidator<TCommand>`) before the handler runs, via `CommandValidationBehavior`. Flag a new command whose handler uses input with no validator registered.
- **TEST-2** 🟡 Validate queries where it matters (IDs, pagination, filters) via `QueryValidationBehavior` (`RuleFor(q => q.Id).NotEmpty()`).
- **TEST-3** 🟡 Validators live in the right place and give meaningful `.WithMessage(...)`; flag unvalidated input flowing straight into `AddAsync`/`SaveChanges`.
- **TEST-4** 🟡 New handlers/services/critical logic should have unit tests; endpoints/repositories covered by integration tests. Flag non-trivial new logic with no accompanying tests.
- **TEST-5** 🔵 Edge cases handled and tested (nulls, empty, enum/date parse failures, boundary values).

## Version Control & Merge Quality (VCS)
- **VCS-1** 🟡 PR is scoped to one feature/fix and linked to a tracked item (Jira/issue). Flag PRs mixing unrelated UI + logic + DB changes, or with no issue link.
- **VCS-6** 🔴 Entity/migration changes and business logic that uses those entities must be in **separate PRs**. PR 1: entity + migration + DbContext config only. PR 2: handlers, services, endpoints that use the new table. Flag any PR that adds a new migration **and** contains handler/service/endpoint logic for the same entity.
- **VCS-2** 🔵 Commit messages: imperative mood, ~50-char subject, reference issue in body. Flag `WIP`, `Updates`, `Fix some stuff`, `Changes from this week`.
- **VCS-3** 🔴 No debug/temporary code committed: flag `Console.WriteLine` debug lines, `debugger;`, `var_dump`, `dd(`, and stray `// TODO` left in shipped logic. (Legitimate audit logging via LoggingBehavior is fine.)
- **VCS-4** 🔵 Prefer atomic commits; build should pass per commit. Note (don't block) if the PR is a single huge mixed commit.
- **VCS-5** 🔵 UI-affecting PRs should include screenshots/steps (rare for backend, but note if applicable).
