# Setup

## Prerequisites

- SQL Server running locally or on a reachable host
- `sqlcmd`
- Java 17+
- Maven 3.9+
- Node.js 20+

## 1. Create and Seed the Database

Create the database once:

```powershell
sqlcmd -S localhost -Q "CREATE DATABASE RTD_DB"
```

Apply schema and sample data:

```powershell
sqlcmd -S localhost -d RTD_DB -i database\schema.sql
sqlcmd -S localhost -d RTD_DB -i database\seed.sql
```

If SQL Server requires SQL authentication, add `-U your_user -P your_password`.

If `seed.sql` reports invalid column names such as `current_status`, verify the actual table structure in `RTD_DB`:

```sql
USE [RTD_DB];
GO

SELECT DB_NAME() AS current_database;

SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME IN ('Services', 'Events', 'LogAnalysis')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

If the expected columns are missing, rerun `database/schema.sql` against `RTD_DB` before running `database/seed.sql`. The schema script drops and recreates the three project tables.

In Visual Studio or SSMS, stale IntelliSense can still show red errors after a successful run. Check the Messages tab after executing the script, then refresh IntelliSense or reopen the query window.

## 2. Start the Spring Boot API

```powershell
cd backend
$env:SPRING_DATASOURCE_URL="jdbc:sqlserver://localhost:1433;databaseName=RTD_DB;encrypt=true;trustServerCertificate=true"
$env:SPRING_DATASOURCE_USERNAME="your_user"
$env:SPRING_DATASOURCE_PASSWORD="your_password"
$env:CORS_ALLOWED_ORIGIN="http://localhost:3000,http://127.0.0.1:3000"
$env:SERVER_PORT="8080"
mvn spring-boot:run
```

Verify:

```powershell
curl.exe http://localhost:8080/api/services
curl.exe "http://localhost:8080/api/events?page=0&size=50"
```

## 3. Start the React Dashboard

```powershell
cd frontend
copy .env.example .env.local
npm install
npm run dev
```

Open `http://localhost:3000`.

Frontend configuration is loaded from `frontend/.env.local`:

```env
VITE_API_URL=http://localhost:8080
VITE_POLL_INTERVAL_MS=30000
VITE_EVENTS_PAGE_SIZE=50
```

## 4. Integration Flow

The current seeded local flow is:

```text
seed.sql sample events
  -> SQL Server
  -> Spring Boot API
  -> React Dashboard
```

The Python processor flow is:

```text
python-service/logs/*.log
  -> Python validator and processor
  -> SQL Server Events and LogAnalysis tables
  -> Spring Boot API
  -> React Dashboard
```

## 5. Run the Python Log Processor

Create a virtual environment and install dependencies:

```powershell
cd python-service
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Create local configuration:

```powershell
copy .env.example .env
```

Update `.env` with your SQL Server settings, then generate a sample log:

```env
DB_SERVER=localhost
DB_NAME=RTD_DB
DB_USER=your_user
DB_PASSWORD=your_password
DB_DRIVER=ODBC Driver 18 for SQL Server
DB_TRUSTED_CONNECTION=false
LOG_DIR=logs
DEFAULT_SERVICE_NAME=application-log
DEFAULT_EVENT_TYPE=LOG_ENTRY
RETENTION_DAYS=30
LOG_LEVEL=INFO
```

```powershell
python sample_data_generator.py
```

Process all `.log` files in `python-service/logs`:

```powershell
python -m processor.log_processor
```

Verify records reached SQL Server:

```powershell
sqlcmd -S localhost -d RTD_DB -Q "SELECT TOP 20 * FROM dbo.Events ORDER BY [timestamp] DESC"
sqlcmd -S localhost -d RTD_DB -Q "SELECT TOP 20 * FROM dbo.LogAnalysis ORDER BY processed_time DESC"
```

## 6. Run Tests

Backend:

```powershell
cd backend
mvn test
```

Frontend:

```powershell
cd frontend
npm test
```

Python:

```powershell
cd python-service
python -m pytest
```
