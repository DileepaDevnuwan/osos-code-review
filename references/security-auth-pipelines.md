# Security, Auth & Pipeline Behaviors (rule prefix: SEC / AUTH / PIPE)

Source: Security Best Practices, 11.6 Authentication/Authorization/Pipelines & Custom Behaviors.

## Security (SEC) — mostly 🔴/🟡
- **SEC-1** 🔴 All input validated with FluentValidation before use. Flag handlers that consume request DTOs with no validator (see also TEST rules).
- **SEC-2** 🔴 Parameterized data access only. LINQ/EF expression queries are safe (EF parameterizes). **Flag** string-concatenated SQL, `FromSqlRaw("... '" + input + "'")`, and dynamic-LINQ built from string concatenation — SQL injection.
- **SEC-3** 🔴 No secrets/credentials/connection strings hardcoded in source or committed. Web-app user secrets live in `secret.json`; system users via Keycloak + central hub. Use env vars / secret managers in prod.
- **SEC-4** 🟡 Never expose domain entities directly in API responses — map to DTOs.
- **SEC-5** 🟡 Don't log or return sensitive data in errors (ties to LOG-1).

## Authentication & Authorization (AUTH)
- **AUTH-1** 🔴 Protected requests must be covered by auth. The system authenticates via JWT bearer middleware (`UseAuthentication`) and optionally the custom `AuthKey` header behavior; authorization is enforced by `AuthorizationBehavior` (grant/menu based). Flag new endpoints/handlers that should require authorization but bypass it (e.g. unwarranted `AllowAnonymous`).
- **AUTH-2** 🟡 Authorization is centralized in the `AuthorizationBehavior` (grants inferred from request name) — don't scatter bespoke `[Authorize]`/role checks that duplicate it.
- **AUTH-3** 🟡 Grants use the `ModuleRoleGrants` enum (All, Read, Create, Edit, Delete, Print, ExportCsvPdf, Execute) — flag magic ints for permissions.
- **AUTH-4** 🟡 API-key path compares against configured key and sets context flags correctly; ensure a failed key check actually **throws** / blocks (the documented `ApiKeyBehavior` bug builds an exception without throwing — see ERR-6).

## Middleware pipeline order (PIPE)
- **PIPE-1** 🟡 If `Program.cs`/startup pipeline is touched, order must hold: RequestLocalization → Swagger(dev) → EnableBuffering → PathBase(`/v2/api`) → CORS(`AllowAngularApp`) → **Authentication → Authorization** → endpoints → ExceptionHandler → HangfireDashboard. Auth must sit before endpoints; ExceptionHandler after.
- **PIPE-2** 🟡 New modules register endpoints with `app.Use<Module>Endpoints()` in the registration section (not `Program.cs` inline, not `Use<Module>ModuleEndpoints()`).

## MediatR behaviors (PIPE-B)
- **PIPE-B1** 🟡 New behaviors implement `IPipelineBehavior<TRequest,TResponse>`, call `await next()` on the pass path, and are registered in the module's `DependencyInjection.cs` via `config.AddOpenBehavior(typeof(XBehavior<,>))`.
- **PIPE-B2** 🔵 Behaviors are scoped to intent (Validation for Command/Query, Logging for non-GET writes, WorkflowApproval on POST responses, RecentlyVisited on GET). Flag a behavior doing unrelated work or running on the wrong HTTP verb.
- **PIPE-B3** 🟡 Behaviors that reflect over responses (e.g. WorkflowApproval) must guard nulls and wrap per-property access in try/catch so one bad property doesn't break the request.
