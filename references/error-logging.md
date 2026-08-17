# Error Handling & Logging (rule prefix: ERR / LOG)

Source: Error Handling & Logging.

## Exceptions (ERR)
- **ERR-1** 🟡 Throw specific / domain / validation exceptions, not bare `throw new Exception("Invalid input")`.
- **ERR-2** 🟡 Handle exceptions at the appropriate layer and return an informative message. Module-level domain exceptions exist (e.g. `RecruitmentDomainException`, `PmoDomainException`) — use them.
- **ERR-3** 🔴 No silent failures: flag `return default;` / empty catch that hides an error, and catches that neither handle nor rethrow.
- **ERR-4** 🟡 Reuse the existing standard exception types for consistent API error responses: `BadRequestException`, `CustomValidationException`, `DomainException`, `ForbiddenException`, `InternalServerException`, `LicenseValidationException`, `NotFoundException`, `NotFoundDictionaryItemException`, `UserLimitExceedException`, `UserRoleExistsException`, `CompanyCountMissMatchException`. Flag ad-hoc new exception types that duplicate these.
- **ERR-5** 🟡 Exception messages must be informative — flag placeholder messages like `base("Exception returned")`.
- **ERR-6** 🔴 A constructed exception must actually be **thrown**. Flag `new SomeException("...");` on its own line whose result is discarded (this real bug exists in `ApiKeyBehavior`).
- **ERR-7** 🟡 Global handling via `UseExceptionHandler` / `CustomExceptionHandler` middleware — don't scatter broad try/catch that duplicates it.

## Logging (LOG)
- **LOG-1** 🔴 Never log secrets: passwords, tokens, API keys, full JWTs. Mask/redact sensitive fields. This is a hard blocker.
- **LOG-2** 🟡 Use appropriate levels (Information/Warning/Error) and structured, meaningful entries — not vague `Console.WriteLine("error")`.
- **LOG-3** 🔵 Audit logging for non-GET writes goes through the `LoggingBehavior` MediatR pipeline (registered via `config.AddOpenBehavior(typeof(LoggingBehavior<,>))`), not hand-rolled per handler.
- **LOG-4** 🔵 Avoid leftover debug logging / `Console.WriteLine` used as a debugger (see also VCS-3).
