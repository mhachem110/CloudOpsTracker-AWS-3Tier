# CloudOpsTracker

Clean, ready-to-open Visual Studio solution for the AWS 3-tier training project.

## Folder layout

- `CloudOpsTracker.Web` = MVC frontend
- `CloudOpsTracker.API` = Web API backend
- SQL Server Express = local database tier

There is only one root project folder: `CloudOpsTracker`.

## Local requirements

- Visual Studio 2026
- .NET 8 SDK
- SQL Server Express at `localhost\SQLEXPRESS`
- SSMS (optional, for viewing the database)

## First run

1. Double-click `CloudOpsTracker.sln`.
2. Restore NuGet packages if Visual Studio asks.
3. Open Package Manager Console.
4. Set Default Project to `CloudOpsTracker.API`.
5. Run:

```powershell
Update-Database
```

6. Configure both projects to start:
   - `CloudOpsTracker.API` = Start
   - `CloudOpsTracker.Web` = Start
7. Run the solution.

Local URLs:
- API health check: `https://localhost:7123/healthz`
- MVC website: `https://localhost:7234`

## Database

The local development connection string is already configured for:

`localhost\SQLEXPRESS`

Database:

`CloudOpsTrackerDb`

## Important for AWS later

Local secrets are only for development. For AWS we will replace configuration using environment variables / AWS secret management instead of hard-coding production credentials.
