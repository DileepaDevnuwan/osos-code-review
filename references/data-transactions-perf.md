# Data, Transactions & Performance (rule prefix: TX / PERF)

Source: Database Transaction Handling, Performance Considerations.

## Transactions (TX) — ACID matters; these are often 🔴/🟡
- **TX-1** 🔴 Multiple related writes that must succeed/fail together are wrapped in ONE transaction (`BeginTransactionAsync` → work → `CommitAsync`). Flag several independent `SaveChangesAsync()` calls that should be atomic.
- **TX-2** 🔴 Every `catch` in a transactional method calls `RollbackAsync()` before rethrowing. Flag any catch that logs/swallows without rolling back — this is the single most important check here.
- **TX-3** 🔴 `CommitAsync()` happens only **after all** operations complete. Flag commit-before-work or commit-in-the-middle then more writes after.
- **TX-4** 🔴 Never swallow the exception (`Console.WriteLine(ex)` then continue) inside a transaction — rethrow after rollback.
- **TX-5** 🟡 No long-running / external calls (HTTP, user interaction) **inside** the transaction scope — do them after commit. Keep the scope short.
- **TX-6** 🟡 Don't coordinate writes across multiple `DbContext`s / connections in one logical unit without a proper distributed strategy; prefer a Unit of Work per logical operation.
- **TX-7** 🟡 No nested transactions unless intentional and supported.
- **TX-8** 🔵 Async DB calls inside transactions use `await`; dispose transaction (`using`); avoid Serializable isolation unless required.
- **TX-9** 🟡 Prefer the Unit of Work pattern (`IUnitOfWork.CommitAsync()`) over scattered `SaveChanges` calls; don't mix ad-hoc transaction handling outside it.

## JSON Columns (DATA)
- **DATA-1** 🔴 Never use `jsonb` or any JSON column type directly on an entity property. JSON properties must be declared as `string` in the entity. The `[JsonColumn]` attribute + `ApplyJsonColumnConventions()` in `OnModelCreating` handles the conversion to `jsonb` (PostgreSQL) or `nvarchar(max)` (SQL Server) automatically.
- **DATA-2** 🟡 Flag `.HasColumnType("jsonb")` or `.HasColumnType("nvarchar(max)")` set manually in Fluent API configuration for JSON properties. Use `[JsonColumn]` attribute on the entity property instead — the convention method applies the correct type per provider.
- **DATA-3** 🟡 Flag entity properties typed as `JsonDocument`, `JsonElement`, `JObject`, or `Dictionary<string, object>` for JSON storage. Use `string` with `[JsonColumn]` — serialization/deserialization is handled at the application layer.

## Audit Fields (AUDIT) — handled by `AuditableEntityInterceptor`
- **AUDIT-1** 🔴 Never manually set audit fields (`CreatedBy`, `CreatedDate` / `CreateUser`, `CreateDate`, `UpdatedBy`, `UpdatedDate` / `UpdateUser`, `UpdateDate`, `ModifiedBy`, `ModifiedDate`). These are populated automatically by `AuditableEntityInterceptor` — manual assignment overrides or conflicts with the interceptor.
- **AUDIT-2** 🟡 Do not map audit fields in commands, DTOs, or `CreateMap` / manual mapping. They must not appear in `CreateStudentCommand`, `UpdateStudentCommand`, or their mapping profiles. The interceptor owns them.
- **AUDIT-3** 🟡 Entities that need auditing should implement the auditable interface/base class so the interceptor picks them up. Flag new entities with audit-like properties that don't inherit from the auditable base.
- **AUDIT-4** 🔵 Do not include audit fields in FluentValidation validators — they are never user-supplied, so validating them is meaningless.

## Performance (PERF)
- **PERF-1** 🔴 No DB queries or un-batched API calls inside loops (N+1). Flag `foreach`/`for` bodies that call the DB per item; use `AddRangeAsync` / `RemoveRange` / bulk ops instead.
- **PERF-6** 🔴 No `SaveChangesAsync()` / `SaveChanges()` inside a loop. Collect all changes first, then call `SaveChangesAsync()` once after the loop. One save per batch, not per iteration.
- **PERF-7** 🔴 No nested loops where the inner loop makes DB calls or does heavy computation that can be avoided. Flatten with lookups (`Dictionary` / `HashSet`), joins, or bulk queries before the loop. Flag `foreach` inside `foreach` that queries or filters on every outer iteration.
- **PERF-2** 🟡 List/collection endpoints are paginated (`PaginationRequest` / `PaginatedResult<T>`); flag `GetAllUsersAsync()`-style unbounded returns.
- **PERF-3** 🟡 Select only needed columns/rows (projection to DTO) for large datasets; don't pull whole entities/graphs when a projection suffices.
- **PERF-4** 🟡 Async handlers await async services; never block with `.Result` on a query handler (also see NET-2).
- **PERF-5** 🔵 Use `.Include()` deliberately to avoid lazy-load N+1; keep `IQueryable` filtering server-side (don't `ToList()` then filter in memory).
- **PERF-8** 🔴 Review logic for time complexity. Minimize nested loops — prefer `O(n)` lookups (`Dictionary` / `HashSet`) over `O(n²)` scans. Pre-fetch all required data before the loop instead of querying per iteration. Flag any algorithm that grows quadratically (or worse) when a linear or log-linear approach exists.

## Mapping (MAP)
- **MAP-1** 🔴 Services and handlers must not contain inline mapping logic (manual property-by-property assignment or `CreateMap` profiles). All entity ↔ DTO / entity ↔ command mapping must be done via **extension methods** (e.g. `student.ToDto()`, `command.ToEntity()`). Flag any mapping code written directly inside a service or handler — extract it to an extension method.
