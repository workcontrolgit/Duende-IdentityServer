# Repository Guidelines

## Project Structure & Module Organization
- `src/` contains the application projects:
  - `DuendeIdentityServer.Admin` and `DuendeIdentityServer.Admin.Api` for the Admin UI/API.
  - `DuendeIdentityServer.STS.Identity` for the IdentityServer host.
  - `DuendeIdentityServer.*.EntityFramework.*` for database provider implementations.
  - `DuendeIdentityServer.Shared` for shared models and utilities.
- `shared/` holds shared assets or tooling for local development.
- Solution file: `DuendeIdentityServer.AdminUI.sln`.

## Build, Test, and Development Commands
- `dotnet build DuendeIdentityServer.AdminUI.sln` — build the entire solution.
- `dotnet run --project src/DuendeIdentityServer.STS.Identity/DuendeIdentityServer.STS.Identity.csproj` — run the IdentityServer host.
- `dotnet run --project src/DuendeIdentityServer.Admin/DuendeIdentityServer.Admin.csproj` — run the Admin UI.
- `dotnet run --project src/DuendeIdentityServer.Admin.Api/DuendeIdentityServer.Admin.Api.csproj` — run the Admin API.
- `docker compose up` — start local dependencies defined in `docker-compose.yml`.

## Coding Style & Naming Conventions
- Language: C# (.NET). Use 4-space indentation and standard C# naming:
  - Types/Methods: `PascalCase`
  - Locals/Parameters: `camelCase`
  - Constants: `PascalCase` or `UPPER_SNAKE_CASE` when clearly constant.
- Keep namespaces aligned to folder structure (e.g., `DuendeIdentityServer.Admin`).

## Testing Guidelines
- No standalone test projects are present; there are configuration sanity checks under `Configuration/Test/StartupTest.cs`.
- When adding tests, prefer `dotnet test` at the solution level and name test projects `*.Tests` (e.g., `DuendeIdentityServer.Admin.Tests`).

## Commit & Pull Request Guidelines
- Commit messages follow a short, imperative style (e.g., `Add project files.`).
- PRs should include:
  - A brief summary of changes and impact.
  - Linked issue or ticket (if applicable).
  - Notes on how to test (commands or environments).

## Security & Configuration Tips
- Store secrets in local configuration (e.g., user secrets or environment variables), not in source.
- Review provider-specific EF projects before changing database settings.
