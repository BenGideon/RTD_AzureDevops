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
sqlcmd -S localhost -Q "CREATE DATABASE RTD_AzureDevops"
```

Apply schema and sample data:

```powershell
sqlcmd -S localhost -d RTD_AzureDevops -i database\schema.sql
sqlcmd -S localhost -d RTD_AzureDevops -i database\seed.sql
```

If SQL Server requires SQL authentication, add `-U your_user -P your_password`.

## 2. Start the Spring Boot API

```powershell
cd backend
$env:SPRING_DATASOURCE_URL="jdbc:sqlserver://localhost:1433;databaseName=RTD_AzureDevops;encrypt=true;trustServerCertificate=true"
$env:SPRING_DATASOURCE_USERNAME="your_user"
$env:SPRING_DATASOURCE_PASSWORD="your_password"
$env:CORS_ALLOWED_ORIGIN="http://localhost:3000,http://127.0.0.1:3000"
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

```powershell
python sample_data_generator.py
```

Process all `.log` files in `python-service/logs`:

```powershell
python -m processor.log_processor
```

Verify records reached SQL Server:

```powershell
sqlcmd -S localhost -d RTD_AzureDevops -Q "SELECT TOP 20 * FROM dbo.Events ORDER BY [timestamp] DESC"
sqlcmd -S localhost -d RTD_AzureDevops -Q "SELECT TOP 20 * FROM dbo.LogAnalysis ORDER BY processed_time DESC"
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
