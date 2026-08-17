# Architecture, CQRS & .NET (rule prefix: ARCH / EP / NET)

Source: 11.5 Endpoints, Maintainability & Modularity, Functionality & Business Logic, Language/Framework-Specific (.NET).
Layered modules: `Modules/<Module>/<Module>.{Application,Domain,Infrastructure,Endpoints}`.

## Endpoints & routing (EP)
- **EP-1** 🟡 Endpoint grouping methods follow `Map` + `Module` + `Endpoints`: `MapStudentEndpoints`. Not `MapCrudStudentEndpoints`.
- **EP-2** 🟡 Route groups are camelCase **plural** (`app.MapGroup("students")`), not `"Students"`.
- **EP-3** 🟡 Action is conveyed by the HTTP verb, not the path. No `/createStudents`, `GetById/{id}`, `/getByCourseId/{id}`. Alternate-key lookups include the property segment: `/courseId/{id}`.
- **EP-4** 🟡 Module endpoints are registered in that module's `DependencyInjection.cs` (via `Use<Module>Endpoints()`), **not** in `Program.cs`. Registration prefix pattern: `app.Use<Module>Endpoints()` — not `Use<Module>ModuleEndpoints()`.
- **EP-5** 🟡 Endpoint bodies are thin: parse request → `sender.Send(...)` → return result. No business logic, DB access, or if/else in the endpoint.

## CQRS / MediatR (ARCH-Q)
- **ARCH-Q1** 🟡 Query/Command names = `[action] + [module plural] + [Query|Command]`: `GetStudentsQuery`, `CreateStudentCommand`. Not `GetStudent`, `StudentCommand`.
- **ARCH-Q2** 🔴 Never mix read and write in one handler/request (no `SaveAndFetchUserHandler`). Queries don't mutate state; commands own side-effects.
- **ARCH-Q3** 🟡 One handler = one responsibility; keep it thin and delegate complex logic to a domain service. Flag handlers that validate + log + audit + update + email in one method.
- **ARCH-Q4** 🟡 Controllers/endpoints only dispatch via MediatR; they must not contain domain `if/else`, DB calls, or business rules.
- **ARCH-Q5** 🔵 Use MediatR for decoupling / cross-cutting behavior, not as a glorified DI call for a single service.

## HttpContext & BaseHandler (ARCH-H)
- **ARCH-H1** 🔴 Never inject `IHttpContextAccessor` in the service layer. Services must not depend on HTTP context — if a service needs user info (e.g. `UserId`, `CompanyCode`), the handler passes it as a parameter.
- **ARCH-H2** 🟡 Handlers that need user/request context must inherit `BaseHandler(IHttpContextAccessor)` instead of injecting `IHttpContextAccessor` directly. `BaseHandler` provides:
  - `UserId` (`Guid`) — logged-in user's ID from JWT claims
  - `LoggedUserEmail` (`string`) — user's email from JWT claims
  - `LoggedUserRoleNames` (`List<string>`) — user's roles (throws if none)
  - `LoggedUserRoleNamesSafe` (`List<string>`) — user's roles (empty list if none)
  - `CompanyCode` (`string`) — from request header
  - `DocumentTypeCode` (`string`) — from request header
  - `CurrentUrl` (`string`) — from request header
  - `SuperAdmin` (`string`) — super admin name from claims
  - `OsosSuperAdmin` (`string`) — OSOS super admin from claims
  - `SuperAdminUserTypeSafe` (`string`) — super admin (empty string if absent)
  - `PaginationRequest()` — parses `top`, `skip`, `orderby`, `filter`, `jsonFilter` from query string
  - `CancellationToken` (`static`) — cancellation token
- **ARCH-H3** 🟡 Flag any handler that manually parses `ClaimTypes`, `ClaimName.*`, or reads request headers for values already exposed by `BaseHandler` — use the base class properties instead of duplicating the logic.

## Business logic & edge cases (ARCH-B)
- **ARCH-B1** 🟡 No business rules hardcoded in controllers/endpoints (`if (user.Age < 18) return BadRequest(...)` belongs in a handler/validator).
- **ARCH-B2** 🟡 No magic strings/numbers (`user.Status == "X1"`, `id == "999"`). Use enums/constants.
- **ARCH-B3** 🟡 Avoid deeply nested conditionals; prefer guard clauses / early returns.
- **ARCH-B4** 🟡 Environment/feature logic is config-driven (`configuration["Environment"] == "Testing"`), not hardcoded `Environment.GetEnvironmentVariable(...)` checks or scattered `bool isTestMode` flags.

## Maintainability / SOLID / DRY (ARCH-S)
- **ARCH-S1** 🔴 DRY: duplicated logic (same mapping, same validation, same query in multiple places, copy-pasted blocks) → extract to an extension method, shared service, or base class. Flag code that could reuse an existing extension method or utility but re-implements the logic inline.
- **ARCH-S6** 🔴 Before writing new helper logic, check if a reusable extension method, base class method, or shared service already exists in the codebase. Flag code that duplicates functionality available in existing extensions or utilities — suggest the existing method instead.
- **ARCH-S2** 🟡 SRP: no "God" service mixing data access + logging + validation + business logic.
- **ARCH-S3** 🟡 DIP: depend on abstractions; don't `new` a repository/logger inside a handler (`new EmployeeRepository()`), inject it.
- **ARCH-S4** 🔵 OCP/LSP/ISP: open for extension w/o modifying switch-on-role blocks; derived types must honor the base contract (no `throw new NotSupportedException()` overrides); no fat interfaces forcing `NotImplementedException`.
- **ARCH-S5** 🟡 One service per purpose per module; register in the module's `DependencyInjection.cs`, not `Program.cs`. Interact with data via well-defined interfaces + DTOs.

## .NET specifics (NET)
- **NET-1** 🔴 No manual `new` of injected dependencies (`var service = new UserService();`). Use constructor injection with correct lifetime (Scoped per request / Singleton app-wide / Transient per resolve).
- **NET-2** 🔴 Async all the way: `await ...Async(...)`. Never `.Result` / `.Wait()` (deadlock/thread-starvation risk). Pass `CancellationToken` through.
- **NET-3** 🟡 Nullable reference types respected: use `?`, guard nulls (`if (tokenDto is null) return Unauthorized();`). Flag `!` null-forgiveness used to silence the compiler, and un-guarded dereferences of nullable values.
- **NET-4** 🔵 Large classes split via `partial` by concern (`.Validations.cs`, `.Exceptions.cs`) rather than one huge file.
- **NET-5** 🔵 Prefer modern C# 12: records for immutable DTOs, pattern matching, nullable enabled.
