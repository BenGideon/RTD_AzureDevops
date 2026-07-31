# Process Monitoring & Automation Dashboard — Design Document

---

## 1. Project Overview

### Purpose

The Process Monitoring & Automation Dashboard is a lightweight internal tool that gives developers a single-screen view of application health. It displays service status and a chronological event log sourced from application log files processed by an automated Python pipeline.

### Problem Being Solved

Developers working on multi-service applications spend time context-switching between log files, terminal windows, and ad hoc scripts to understand what is happening. This tool consolidates that information into one refreshing dashboard backed by a structured database, making it easier to spot errors and trace recent activity without digging through raw files.

### Target Users

Solo developers or small development teams running internal applications in a local or private network environment. No external users.

### Expected Outcome

A complete, working full-stack application that demonstrates:
- A React frontend dashboard with auto-refresh
- A Spring Boot REST API with basic authentication
- SQL Server database storing service status and event history
- Python automation that reads log files, validates them, and writes results to the database
- An Azure DevOps CI/CD pipeline that builds, tests, and validates all three stacks

---

## 2. Scope Definition

### Included

| Area | What is Built |
|---|---|
| Dashboard | React single-page dashboard with 30-second polling auto-refresh |
| Service status | Display current UP/DOWN/UNKNOWN status per service |
| Event tracking | Chronological log of application events with severity, type, and timestamp |
| Log processing | Python scripts that read log files, validate format, and write to SQL Server |
| Data storage | SQL Server database with three tables: Services, Events, LogAnalysis |
| REST API | Spring Boot endpoints: GET /services, GET /events (paginated), POST /events |
| Authentication | Spring Security HTTP Basic auth; credentials from environment variables |
| DevOps workflow | Azure DevOps pipeline: build, test (all three stacks), coverage gate, release prep |
| Sample data | Python utility that generates sample INFO/WARNING/ERROR log lines for local testing |

### Not Included

| Area | Reason |
|---|---|
| AI/ML anomaly detection | Unnecessary complexity for this scope |
| Kubernetes | Enterprise infrastructure; not needed for a single-developer project |
| Microservices | Single-responsibility services; monolith is appropriate here |
| Complex alerting (email, Slack, PagerDuty) | Out of scope; a TODO for future versions |
| Enterprise-scale monitoring | This is an internal dev tool, not production observability infrastructure |
| Real-time streaming (WebSocket, SSE, Kafka) | 30-second polling is sufficient for this use case |
| OAuth / SSO | Internal tool; HTTP Basic auth is sufficient |
| Data archiving beyond 30-day retention | Addressed by cleanup script; deeper archival strategy is out of scope |

---

## 3. System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        DEVELOPER BROWSER                         │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              React Dashboard (port 3000)                   │   │
│  │  Polls every 30s  →  GET /services, GET /events           │   │
│  └─────────────────────────┬────────────────────────────────┘   │
└────────────────────────────┼────────────────────────────────────┘
                             │ HTTP + Basic Auth
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Spring Boot REST API (port 8080)                    │
│                                                                   │
│  Spring Security → Controller → Service → Repository             │
│  CORS: allows origin http://localhost:3000                        │
└─────────────────────────────┬────────────────────────────────────┘
                             │ JDBC / JPA
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        SQL Server Database                        │
│                                                                   │
│  services       events (indexed)        log_analysis             │
└─────────────────────────────▲────────────────────────────────────┘
                             │ JDBC / pyodbc
                             │
┌─────────────────────────────┴────────────────────────────────────┐
│          Python Log Processor (Windows Task Scheduler)            │
│                                                                   │
│  Every 5 min: read logs/ → validate → MERGE into DB              │
│  At startup: DELETE events older than 30 days                     │
└──────────────────────────────────────────────────────────────────┘

Azure DevOps manages:
  ├── Source control (git repository)
  ├── Build pipeline (Maven + npm)
  ├── Test pipeline (JUnit + React Testing Library + pytest + Playwright)
  ├── Coverage gate (80% minimum, all three stacks)
  └── Release preparation (artifact packaging + documentation check)
```

### Component Responsibilities

**React Dashboard**
- Renders the service status cards and event table
- Polls `GET /services` and `GET /events` every 30 seconds via `setInterval`
- Sends `Authorization: Basic <base64>` header on every request
- Shows loading state, error state (API unreachable), and empty state (no data)

**Spring Boot REST API**
- Exposes three REST endpoints under `/api`
- Enforces HTTP Basic authentication on all endpoints via Spring Security
- Configures CORS to allow requests from `http://localhost:3000`
- Delegates to JPA repositories for all database access
- Returns standard HTTP error codes (400 invalid input, 401 unauthorized, 500 server error)

**SQL Server Database**
- Stores service status, event history, and log processing metadata
- Enforces unique constraint on Events to prevent duplicate inserts
- Provides indexed lookups by timestamp, severity, and service name
- Retains events for 30 days; older rows deleted by Python cleanup step

**Python Log Processor**
- Reads structured log files from the `logs/` directory
- Validates each line (must contain severity level + message)
- Upserts valid events using SQL Server `MERGE` statement (no duplicates)
- Deletes events older than 30 days at each run start
- Runs every 5 minutes via Windows Task Scheduler
- Logs its own activity (lines processed, errors skipped, DB write results) to `logs/scheduler.log`

---

## 4. Application Workflow

```
Application Log Files (logs/*.log)
          │
          │ Python reads on 5-minute Task Scheduler trigger
          ▼
Log Validator (validator/log_validator.py)
  ├── Valid line: parse severity, message, timestamp
  └── Invalid line: log to scheduler.log, skip
          │
          ▼
Log Processor (processor/log_processor.py)
  ├── Cleanup: DELETE Events WHERE timestamp < DATEADD(day,-30,GETDATE())
  └── MERGE INTO Events (deduplication via unique constraint)
          │
          ▼
SQL Server Database
  ├── services table (updated manually or via POST /services if added later)
  ├── events table (populated by Python processor)
  └── log_analysis table (run metadata: file processed, count, errors)
          │
          │ Spring Boot reads on HTTP request
          ▼
Spring Boot REST API
  ├── GET /api/services → ServiceRepository.findAll()
  ├── GET /api/events?page=0&size=50 → EventRepository.findAll(Pageable)
  └── POST /api/events → EventRepository.save(event)
          │
          │ React polls every 30 seconds
          ▼
React Dashboard
  ├── ServiceStatus cards: one per service, colored by status
  ├── EventTable: most recent 50 events, paginated
  └── EventDetails: expandable row with full message
```

---

## 5. Functional Requirements

### Dashboard

- Displays all service status cards at the top of the page
- Below status cards, shows a paginated table of the most recent events (50 per page)
- Auto-refreshes every 30 seconds without a full page reload (polling via `setInterval`)
- Shows a loading spinner on first load
- Shows a user-visible error message if the API is unreachable
- Shows an empty state message if there are no services or no events

### Event Tracking

| Field | Type | Description |
|---|---|---|
| id | INT (PK, IDENTITY) | Auto-incremented primary key |
| service_name | NVARCHAR(100) | Name of the service that generated the event |
| event_type | NVARCHAR(50) | Category of event (e.g., STARTUP, HEALTH_CHECK, DB_CONNECT) |
| severity | NVARCHAR(10) | INFO / WARNING / ERROR |
| message | NVARCHAR(500) | Human-readable event description |
| timestamp | DATETIME2 | When the event occurred |

### Service Monitoring

| Field | Type | Description |
|---|---|---|
| id | INT (PK, IDENTITY) | Auto-incremented primary key |
| service_name | NVARCHAR(100) | Unique service identifier |
| current_status | NVARCHAR(10) | UP / DOWN / UNKNOWN |
| last_updated | DATETIME2 | Timestamp of last status change |

### Python Automation

- Reads all `.log` files in the configured `logs/` directory
- Validates each line against the expected format: `[SEVERITY] [TIMESTAMP] message`
- Skips malformed lines and logs them to `logs/scheduler.log` with line number
- Identifies ERROR severity events and counts them in the LogAnalysis record
- Upserts events into SQL Server using `MERGE` statement (see Section 7)
- Writes one LogAnalysis record per log file per run (file path, run time, counts)
- Deletes events older than 30 days at the start of each run

---

## 6. Non-Functional Requirements

### Performance

- Dashboard initial load: under 2 seconds on localhost
- `GET /events` with pagination: under 200ms with indexes (see Section 7)
- `GET /services`: under 100ms (small table, no pagination needed)
- Python processor run time: under 30 seconds for a 10,000-line log file
- React DOM update on poll: no visible flicker (state diff, not full re-render)

### Maintainability

- Each layer (frontend / backend / Python) is an independent folder with its own dependencies
- Spring Boot follows standard package structure: `controller`, `service`, `repository`, `entity`, `exception`, `config`
- Python is organized into `processor/`, `validator/`, `config/` with no cross-package imports except through `config/`
- No hardcoded values in any layer (all from environment or config files)
- File length target: under 200 lines per file; split if larger

### Security

- Spring Security HTTP Basic auth on all API endpoints
- Credentials (`APP_USERNAME`, `APP_PASSWORD`) loaded from environment variables at startup; Spring Boot fails fast if missing
- Database credentials (`SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`) loaded from environment variables; never in source code
- Python DB credentials loaded from environment variables (`DB_SERVER`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`); never in `config.py` directly
- **Authentication scope:** Basic auth applies to all endpoints. This is an internal tool; no external-facing endpoints.
- CORS: `http://localhost:3000` only; `*` wildcard is never used

### Reliability

- Python processor: if the log file is missing, logs the error to `scheduler.log` and exits cleanly (no crash)
- Python processor: if the DB is unreachable, logs the connection error and exits; next scheduled run retries
- Python processor: if a line is malformed, skips that line and continues (no partial-run failure)
- Spring Boot: global exception handler (`@ControllerAdvice`) returns structured JSON error responses for 400/401/500
- React: API error caught in `catch` block; dashboard shows error banner instead of blank screen

### Reliability — Python Failure Modes

| Failure | Behavior |
|---|---|
| Log file not found | Log error to `scheduler.log`, exit 0 (Task Scheduler sees success, no retry storm) |
| DB connection refused | Log error, exit 1 (Task Scheduler logs failure) |
| Malformed log line | Skip line, increment `errors_found` counter, continue |
| MERGE constraint violation | Duplicate silently ignored (MERGE WHEN NOT MATCHED condition) |
| Partial run (crash mid-file) | Next run re-processes from the start; MERGE ensures no duplicates |

---

## 7. Database Design

### Table: services

```sql
CREATE TABLE services (
    id           INT          NOT NULL IDENTITY(1,1) PRIMARY KEY,
    service_name NVARCHAR(100) NOT NULL UNIQUE,
    current_status NVARCHAR(10) NOT NULL DEFAULT 'UNKNOWN'
                               CHECK (current_status IN ('UP','DOWN','UNKNOWN')),
    last_updated DATETIME2    NOT NULL DEFAULT GETDATE()
);
```

### Table: events

```sql
CREATE TABLE events (
    id           INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    service_name NVARCHAR(100) NOT NULL,
    event_type   NVARCHAR(50)  NOT NULL,
    severity     NVARCHAR(10)  NOT NULL
                               CHECK (severity IN ('INFO','WARNING','ERROR')),
    message      NVARCHAR(500) NOT NULL,
    timestamp    DATETIME2     NOT NULL,

    CONSTRAINT UQ_events_dedup
        UNIQUE (service_name, event_type, timestamp, message)
);

-- Query support indexes
CREATE NONCLUSTERED INDEX IX_Events_Timestamp
    ON events (timestamp DESC);

CREATE NONCLUSTERED INDEX IX_Events_Severity
    ON events (severity);

CREATE NONCLUSTERED INDEX IX_Events_ServiceName
    ON events (service_name);
```

### Table: log_analysis

```sql
CREATE TABLE log_analysis (
    id                INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    log_file_path     NVARCHAR(500) NOT NULL,
    processed_at      DATETIME2     NOT NULL DEFAULT GETDATE(),
    records_processed INT           NOT NULL DEFAULT 0,
    errors_found      INT           NOT NULL DEFAULT 0
);
```

### Relationships

```
services.service_name ← (soft reference) → events.service_name
  (no enforced FK — service_name in events may outlive a service record
   that was renamed or removed; kept as a display label, not a constraint)

log_analysis is independent; records per-run metadata only
```

### Data Retention

At the start of each Python processor run:

```sql
DELETE FROM events
WHERE timestamp < DATEADD(day, -30, GETDATE());
```

This keeps the events table bounded. For demo use, 30 days is more than enough. Adjust the interval in `config.py` if needed.

### Deduplication — MERGE Statement

Python uses a SQL Server `MERGE` to avoid duplicates:

```sql
MERGE INTO events AS target
USING (VALUES (?, ?, ?, ?, ?)) AS source
    (service_name, event_type, severity, message, timestamp)
ON (
    target.service_name = source.service_name AND
    target.event_type   = source.event_type   AND
    target.timestamp    = source.timestamp    AND
    target.message      = source.message
)
WHEN NOT MATCHED THEN
    INSERT (service_name, event_type, severity, message, timestamp)
    VALUES (source.service_name, source.event_type, source.severity,
            source.message, source.timestamp);
```

---

## 8. Backend Design

### Package Structure

```
backend/src/main/java/com/rtd/dashboard/
    config/
        SecurityConfig.java         # Spring Security basic auth, env vars
        CorsConfig.java             # CorsConfigurationSource bean
        DatabaseConfig.java         # DataSource properties (from env vars)
    controller/
        ServiceController.java      # GET /api/services
        EventController.java        # GET /api/events, POST /api/events
    service/
        ServiceService.java
        EventService.java
    repository/
        ServiceRepository.java      # extends JpaRepository<Service, Integer>
        EventRepository.java        # extends JpaRepository<Event, Integer> + Page support
    entity/
        Service.java                # @Entity, fields match services table
        Event.java                  # @Entity, fields match events table
    exception/
        GlobalExceptionHandler.java # @ControllerAdvice, handles 400/401/500
        ErrorResponse.java          # standard error JSON shape
```

### REST API

#### `GET /api/services`

- **Purpose:** Return current status of all services.
- **Auth:** Required (Basic).
- **Response 200:**
  ```json
  [
    { "id": 1, "serviceName": "auth-service", "currentStatus": "UP", "lastUpdated": "2026-07-31T10:00:00" },
    { "id": 2, "serviceName": "payment-service", "currentStatus": "DOWN", "lastUpdated": "2026-07-31T09:55:00" }
  ]
  ```
- **Response 401:** Missing or invalid credentials.

#### `GET /api/events?page=0&size=50`

- **Purpose:** Return a paginated list of events, most recent first.
- **Auth:** Required (Basic).
- **Query params:** `page` (0-based, default 0), `size` (default 50, max 100).
- **Response 200:**
  ```json
  {
    "content": [
      { "id": 10, "serviceName": "auth-service", "eventType": "STARTUP", "severity": "INFO",
        "message": "Service started", "timestamp": "2026-07-31T10:01:00" }
    ],
    "totalElements": 342,
    "totalPages": 7,
    "number": 0,
    "size": 50
  }
  ```
- **Response 400:** Invalid `page` or `size` parameter.
- **Response 401:** Missing or invalid credentials.
- **Data flow:** Controller → EventService.findAllPaginated(Pageable) → EventRepository.findAll(Pageable) ordered by timestamp DESC

#### `POST /api/events`

- **Purpose:** Create a new event record. Used by the Python processor and optionally by other services.
- **Auth:** Required (Basic).
- **Request body:**
  ```json
  { "serviceName": "auth-service", "eventType": "DB_CONNECT", "severity": "ERROR",
    "message": "Database connection failed", "timestamp": "2026-07-31T10:05:00" }
  ```
- **Response 201:** Created event object with generated `id`.
- **Response 400:** Missing required fields or invalid `severity` value.
- **Response 401:** Missing or invalid credentials.

### CORS Configuration

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of("http://localhost:3000"));
    config.setAllowedMethods(List.of("GET", "POST", "OPTIONS"));
    config.setAllowedHeaders(List.of("*"));
    config.setAllowCredentials(true);
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/api/**", config);
    return source;
}
```

### Authentication Configuration

Credentials are loaded from environment variables. Spring Boot startup fails if they are missing.

```yaml
# application.yml
app:
  security:
    username: ${APP_USERNAME}
    password: ${APP_PASSWORD}
spring:
  datasource:
    url: ${SPRING_DATASOURCE_URL}
    username: ${SPRING_DATASOURCE_USERNAME}
    password: ${SPRING_DATASOURCE_PASSWORD}
```

---

## 9. Frontend Design

### Project Structure

```
frontend/src/
    pages/
        Dashboard.tsx           # main page, orchestrates polling + layout
    components/
        ServiceStatus.tsx       # single service card (name + status badge)
        EventTable.tsx          # paginated event list with page controls
        EventDetails.tsx        # expandable row showing full event message
        ErrorBanner.tsx         # shown when API is unreachable
        LoadingSpinner.tsx      # shown on initial load
    hooks/
        useServices.ts          # fetches GET /api/services, re-fetches on interval
        useEvents.ts            # fetches GET /api/events?page=&size=, re-fetches on interval
    lib/
        apiClient.ts            # fetch wrapper: base URL + Basic auth header injection
        types.ts                # TypeScript interfaces: Service, Event, PaginatedResponse
    styles/
        global.css
```

### State Management

React built-in state (`useState`, `useEffect`) is sufficient. No Redux or external store needed.

Each custom hook (`useServices`, `useEvents`) owns its own state:
- `data`: current API result
- `loading`: boolean for initial load
- `error`: string or null for API failure

Dashboard component reads from both hooks and passes data to child components as props.

### API Communication

`apiClient.ts` wraps `fetch` with:
- Base URL from `REACT_APP_API_URL` environment variable (default: `http://localhost:8080`)
- `Authorization: Basic <base64(username:password)>` header from `REACT_APP_API_USERNAME` and `REACT_APP_API_PASSWORD` env vars
- JSON content-type header
- Response error checking (non-2xx throws)

Polling is implemented in `useServices` and `useEvents` via `setInterval` inside `useEffect`, with cleanup on unmount.

```typescript
// useEvents.ts — simplified shape
useEffect(() => {
    const fetchData = () => apiClient.get(`/api/events?page=${page}&size=50`)
        .then(setData).catch(setError);
    fetchData();
    const interval = setInterval(fetchData, 30_000);
    return () => clearInterval(interval);
}, [page]);
```

### Pages and Components

| Component | Responsibility |
|---|---|
| `Dashboard` | Layout, coordinates polling hooks, passes data to children |
| `ServiceStatus` | Single card: service name + colored UP/DOWN/UNKNOWN badge |
| `EventTable` | Table of events with pagination controls (Prev / page N of M / Next) |
| `EventDetails` | Expandable table row showing full severity, type, and message |
| `ErrorBanner` | Red banner: "Could not reach the API. Retrying in 30s." |
| `LoadingSpinner` | Centered spinner shown while `loading === true` on initial mount |

---

## 10. Python Automation Design

### Project Structure

```
python-service/
    logs/
        sample.log              # sample input log file
        scheduler.log           # output log from the processor itself
    processor/
        log_processor.py        # main runner: cleanup, read, validate, merge
    validator/
        log_validator.py        # validates a single log line; returns parsed fields or None
    config/
        config.py               # loads all settings from environment variables
    sample_data_generator.py    # generates sample log lines into logs/sample.log
    requirements.txt            # pyodbc, python-dotenv
    .env.example                # documents all required env vars (no actual values)
```

### Components

**`config/config.py`**
Loads and exposes all configuration. Fails fast with a clear error if any required env var is missing:
```python
DB_SERVER = os.environ["DB_SERVER"]
DB_NAME   = os.environ["DB_NAME"]
DB_USER   = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]
LOG_DIR   = os.environ.get("LOG_DIR", "logs")
RETENTION_DAYS = int(os.environ.get("RETENTION_DAYS", "30"))
```

**`validator/log_validator.py`**
Parses a single log line. Returns a dict `{severity, event_type, message, timestamp}` on success or `None` on failure.
Expected log format:
```
INFO  2026-07-31 10:01:00 Service started
WARNING 2026-07-31 10:02:00 Response delay detected
ERROR 2026-07-31 10:03:00 Database connection failed
```

**`processor/log_processor.py`**
Main entry point:
1. Connects to SQL Server via `pyodbc`
2. Deletes events older than `RETENTION_DAYS` days
3. For each `.log` file in `LOG_DIR`:
   a. Opens and reads line by line
   b. Calls `log_validator.parse_line()` on each line
   c. Batches valid parsed events
   d. Runs MERGE statement for each batch
   e. Writes a `log_analysis` record (file path, run time, counts)
4. Closes connection
5. Logs summary to `scheduler.log`

**`sample_data_generator.py`**
Generates a `logs/sample.log` file with randomized INFO/WARNING/ERROR entries across multiple service names. This is used for local development and CI testing where no real application logs exist.

```python
SERVICES = ["auth-service", "payment-service", "user-service"]
EVENTS = [
    ("INFO", "STARTUP", "Service started"),
    ("WARNING", "HEALTH_CHECK", "Response delay detected"),
    ("ERROR", "DB_CONNECT", "Database connection failed"),
]
```

Why this exists: the pipeline has no real services to monitor. The generator provides deterministic, reproducible test data so the dashboard and processor can be developed and tested independently.

---

## 11. Error Handling Strategy

### Frontend

| Scenario | Behavior |
|---|---|
| API unreachable (network error) | `ErrorBanner` shows; polling continues every 30s |
| API returns 401 | `ErrorBanner` shows "Authentication failed. Check credentials." |
| API returns 500 | `ErrorBanner` shows "Server error. Retrying." |
| Empty services list | Services section shows "No services registered yet." |
| Empty events list | EventTable shows "No events found." |
| Pagination out of range | `useEvents` clamps page to 0 if API returns 400 |

### Backend

| Scenario | Behavior |
|---|---|
| Missing required field on POST | GlobalExceptionHandler returns 400 + JSON error message |
| Invalid severity value | Bean validation returns 400 + field-level error |
| DB connection failure | Spring returns 500; `GlobalExceptionHandler` logs stack trace, returns generic error message (no internals leaked) |
| Unauthenticated request | Spring Security returns 401 with `WWW-Authenticate: Basic` header |
| Page param negative or non-integer | Spring Data throws, handler returns 400 |

### Python

| Scenario | Behavior |
|---|---|
| Log file missing | Log "File not found: {path}" to scheduler.log; skip file; continue with others |
| DB connection refused | Log error + exception; exit with code 1 |
| Malformed log line | Log "Skipped line {n}: {line}" to scheduler.log; increment `errors_found`; continue |
| MERGE finds duplicate | Row silently not inserted (WHEN NOT MATCHED condition); no error |
| Partial run (crash mid-file) | Next scheduled run restarts from scratch; MERGE deduplication ensures no data corruption |

---

## 12. Testing Strategy

### Coverage Target: 80% across all three stacks

#### Backend — JUnit 5 + Mockito + JaCoCo

Test types:
- **Unit tests:** Service classes mocked (EventService, ServiceService) covering happy path, empty result, validation errors
- **Integration tests:** `@SpringBootTest` + `@AutoConfigureMockMvc` against embedded H2 for API endpoint tests; covers 200, 201, 400, 401 responses
- **Coverage gate:** JaCoCo Maven plugin fails the build if instruction coverage < 80%

Key test cases:
- `GET /api/events?page=0&size=50` returns paginated response, correct structure
- `POST /api/events` with valid body returns 201
- `POST /api/events` with missing `severity` returns 400
- Unauthenticated request to any endpoint returns 401
- `EventService.findAllPaginated()` returns correct Page object

#### Frontend — React Testing Library + Vitest

Test types:
- **Component tests:** render with props, assert output (no mocking of DOM)
- **Hook tests:** mock `apiClient`, assert state transitions (loading → data, loading → error)

Key test cases:
- `ServiceStatus` renders green badge for `status=UP`, red for `DOWN`, gray for `UNKNOWN`
- `EventTable` renders event rows; renders "No events found" for empty array
- `Dashboard` renders `ErrorBanner` when hook returns error
- `useEvents` starts polling on mount; clears interval on unmount

Coverage gate: Vitest with `--coverage` configured to fail if line coverage < 80%.

#### Python — pytest + coverage.py

Test types:
- **Unit tests:** `log_validator.parse_line()` with valid and invalid inputs
- **Integration tests:** processor runs against a test SQL Server database or mocked `pyodbc` connection

Key test cases:
- `parse_line("INFO 2026-07-31 10:00:00 Service started")` returns correct dict
- `parse_line("not a valid line")` returns `None`
- `parse_line("")` returns `None`
- Processor with a log file containing 3 valid lines + 1 malformed: 3 rows upserted, 1 skipped
- Processor with missing log file: logs error, returns without crash

Coverage gate: `pytest --cov=. --cov-fail-under=80`

#### E2E — Playwright

Three critical flows:

1. **Dashboard loads:** navigate to `/`, verify service cards visible, verify event table visible with at least one row (requires backend + DB running with sample data)

2. **Auto-refresh fires:** load dashboard, spy on network requests, wait 31 seconds, assert that `GET /api/services` and `GET /api/events` were each called at least twice

3. **Event pagination works:** load dashboard, assert page 1 shows ≤50 rows, click "Next", assert new set of rows loaded, assert page counter incremented

---

## 13. Configuration Management

### Principle

No credentials, connection strings, or environment-specific values in source code. All configuration is injected at runtime via environment variables. The application fails fast with a clear error if a required variable is missing.

### Spring Boot (`application.yml`)

```yaml
spring:
  datasource:
    url: ${SPRING_DATASOURCE_URL}
    username: ${SPRING_DATASOURCE_USERNAME}
    password: ${SPRING_DATASOURCE_PASSWORD}
    driver-class-name: com.microsoft.sqlserver.jdbc.SQLServerDriver
  jpa:
    hibernate:
      ddl-auto: validate   # schema is managed by SQL scripts, not JPA auto-create
    show-sql: false

app:
  security:
    username: ${APP_USERNAME}
    password: ${APP_PASSWORD}
  cors:
    allowed-origin: ${CORS_ALLOWED_ORIGIN:http://localhost:3000}
```

For local development, create `application-local.yml` (git-ignored) or use a `.env` file with a tool like `spring-dotenv`.

### Python (`config/config.py` + `.env`)

```python
from dotenv import load_dotenv
load_dotenv()  # reads .env file if present; env vars take precedence

DB_SERVER    = os.environ["DB_SERVER"]       # required
DB_NAME      = os.environ["DB_NAME"]         # required
DB_USER      = os.environ["DB_USER"]         # required
DB_PASSWORD  = os.environ["DB_PASSWORD"]     # required
LOG_DIR      = os.environ.get("LOG_DIR", "logs")
RETENTION_DAYS = int(os.environ.get("RETENTION_DAYS", "30"))
```

`.env.example` is committed to the repository:
```
DB_SERVER=localhost
DB_NAME=rtd_dashboard
DB_USER=your_user
DB_PASSWORD=your_password
LOG_DIR=logs
RETENTION_DAYS=30
```

`.env` is in `.gitignore` and is never committed.

### React (`.env.local`)

```
REACT_APP_API_URL=http://localhost:8080
REACT_APP_API_USERNAME=your_username
REACT_APP_API_PASSWORD=your_password
```

`.env.local` is git-ignored. `.env.example` is committed with placeholder values.

---

## 14. Sample Data Generation

### Purpose

The Python log processor expects `.log` files in the `logs/` directory. During development and CI testing, there are no real application logs. The sample data generator creates a reproducible set of log lines that can be processed through the full pipeline.

### What It Generates

Running `python sample_data_generator.py` creates `logs/sample.log` with 50 randomized log lines:

```
INFO  2026-07-31 10:00:00 auth-service Service started
WARNING 2026-07-31 10:00:05 payment-service Response delay detected
ERROR  2026-07-31 10:00:10 user-service Database connection failed
INFO  2026-07-31 10:00:15 auth-service Health check passed
...
```

Each line uses the format the validator expects: `SEVERITY TIMESTAMP SERVICE_NAME message`.

### Why This Exists

- Developers can run the full pipeline locally without a real application
- CI pipeline can run the Python processor against generated data and verify DB writes
- E2E Playwright tests need data pre-loaded before the browser test runs
- The generator is deterministic (seeded random) so tests are reproducible

---

## 15. Azure DevOps Pipeline Design

```
Developer commits to feature branch
          │
          ▼
┌─────────────────────────────────────┐
│  Stage 1: Build                      │
│  ├── Maven: mvn clean package        │
│  ├── npm: npm ci && npm run build    │
│  └── pip: pip install -r requirements│
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│  Stage 2: Test                       │
│  ├── JUnit: mvn test                 │
│  ├── React: npm test -- --coverage   │
│  └── Python: pytest --cov --cov-fail │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│  Stage 3: Coverage Validation        │
│  ├── JaCoCo report: ≥80% required    │
│  ├── Vitest coverage: ≥80% required  │
│  └── coverage.py: ≥80% required     │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│  Stage 4: Release Preparation        │
│  ├── Package Spring Boot JAR         │
│  ├── Package React build/ folder     │
│  ├── Package python-service/ folder  │
│  └── Publish artifacts to feed      │
└─────────────────────────────────────┘
```

### Pipeline Stages

**Stage 1 — Build**
- Runs on Microsoft-hosted `windows-latest` agent (matches dev environment)
- Maven build with `skipTests=true` (tests run in Stage 2)
- npm `ci` for reproducible frontend install
- pip install for Python dependencies

**Stage 2 — Test**
- All three test suites run in parallel tasks where possible
- JUnit results published as test run in Azure DevOps
- React coverage report published as artifact
- Python coverage report published as artifact
- Playwright E2E: runs against a pre-started Spring Boot process on the agent (using `mvn spring-boot:run &`)

**Stage 3 — Coverage Validation**
- Pipeline fails if any stack is below 80%
- JaCoCo: configured in `pom.xml` with `<haltOnFailure>true</haltOnFailure>`
- Vitest: `--coverage --reporter=json` fails on threshold
- pytest: `--cov-fail-under=80`

**Stage 4 — Release Preparation**
- Packages all three artifacts
- Publishes to Azure Artifacts feed
- Generates release notes from git log since last tag

### Azure DevOps Free Tier Notes

- 1 Microsoft-hosted parallel job, 1,800 minutes/month
- Each full pipeline run estimated at 8–12 minutes
- At 150 runs/month capacity; sufficient for active solo development
- **Do not** use Azure Pipelines for the 5-minute Python scheduled run — that alone would consume 720+ hours/month (use Windows Task Scheduler on the dev machine instead)

---

## 16. Project Folder Structure

```
RTD_AzureDevops/
    frontend/                   # React application
        src/
            pages/
            components/
            hooks/
            lib/
        public/
        package.json
        .env.example
    backend/                    # Spring Boot application
        src/main/java/com/rtd/dashboard/
            config/
            controller/
            service/
            repository/
            entity/
            exception/
        src/main/resources/
            application.yml
        src/test/
        pom.xml
        .env.example
    python-service/             # Python log processor
        logs/
        processor/
        validator/
        config/
        sample_data_generator.py
        requirements.txt
        .env.example
    database/                   # SQL scripts
        schema.sql              # CREATE TABLE statements + indexes
        seed.sql                # initial service rows
        migrations/             # numbered migration scripts if schema changes
    docs/
        DESIGN.md               # this document
        SETUP.md                # local development setup instructions
        PIPELINE.md             # Azure DevOps pipeline setup notes
    .gitignore
    README.md
```

### Folder Explanations

| Folder | Content |
|---|---|
| `frontend/` | React application; self-contained, own `package.json` |
| `backend/` | Spring Boot application; Maven `pom.xml` at root |
| `python-service/` | Python processor; own `requirements.txt`; has `logs/` for I/O |
| `database/` | SQL scripts only; schema is source-controlled, not auto-generated |
| `docs/` | Design, setup, and pipeline documentation |

---

## 17. Development Implementation Order

### Phase 1 — Foundation

1. **Set up repository and folder structure** (`README.md`, `.gitignore`, folder scaffolding, `docs/`)
2. **Database schema** (`database/schema.sql` — tables, indexes, unique constraint; `seed.sql` — initial service rows)
3. **Spring Boot backend** — entities, repositories, services, controllers, exception handler, CORS, security config; `GET /services` and `GET /events` endpoints first
4. **Verify backend** — run locally, call endpoints with Postman or curl, confirm 200/401 responses

### Phase 2 — Frontend

5. **React scaffold** — `create-react-app` or Vite, install RTL/Vitest, configure `.env.example`
6. **`apiClient.ts`** — fetch wrapper with Basic auth header
7. **`useServices` and `useEvents` hooks** — fetch + poll + error state
8. **`ServiceStatus` and `EventTable` components** — render from props
9. **`Dashboard` page** — wire hooks to components, loading/error states
10. **Verify frontend** — run with backend, confirm dashboard loads and polls

### Phase 3 — Python Automation

11. **`sample_data_generator.py`** — generate `logs/sample.log`
12. **`log_validator.py`** — parse single log line, return dict or None
13. **`log_processor.py`** — cleanup step, read files, validate, MERGE, write log_analysis
14. **Verify Python** — run against sample.log, confirm rows appear in DB, confirm duplicate protection works
15. **Windows Task Scheduler setup** — document trigger settings in `docs/SETUP.md`

### Phase 4 — Testing

16. **Backend tests** — JUnit unit tests for services; `@SpringBootTest` integration tests for controllers; verify JaCoCo 80% gate
17. **Frontend tests** — RTL component tests; hook tests with mocked `apiClient`; Vitest coverage gate
18. **Python tests** — pytest unit tests for validator; integration test for processor with test DB
19. **Playwright E2E** — 3 critical flow tests; requires backend + DB running

### Phase 5 — DevOps and Documentation

20. **Azure DevOps pipeline** — `azure-pipelines.yml`; Stages 1–4 as defined in Section 15
21. **`docs/SETUP.md`** — local dev setup: prerequisites, env var setup, run order (DB → backend → frontend → Python)
22. **`docs/PIPELINE.md`** — Azure DevOps pipeline setup steps; Task Scheduler setup for Python

---

## 18. Definition of Done

### Application Checklist

- [ ] Dashboard loads in browser and displays service status cards
- [ ] Dashboard displays event table with pagination controls
- [ ] Dashboard auto-refreshes every 30 seconds (visible via browser network tab)
- [ ] `GET /api/services` returns 200 with service list; 401 without credentials
- [ ] `GET /api/events?page=0&size=50` returns paginated response with metadata
- [ ] `POST /api/events` creates a new event; returns 400 on invalid input
- [ ] Python processor reads `sample.log`, writes events to DB, writes log_analysis record
- [ ] Python processor re-run does not create duplicate events
- [ ] Python processor deletes events older than 30 days on startup
- [ ] Windows Task Scheduler triggers processor every 5 minutes (verified manually)

### Engineering Checklist

- [ ] All required environment variables documented in `.env.example` for each layer
- [ ] No credentials or connection strings in source code
- [ ] Backend: JaCoCo reports ≥80% instruction coverage
- [ ] Frontend: Vitest reports ≥80% line coverage
- [ ] Python: coverage.py reports ≥80% coverage
- [ ] Playwright: 3 E2E tests pass (dashboard load, auto-refresh, pagination)
- [ ] `GlobalExceptionHandler` returns structured JSON for 400, 401, 500
- [ ] React shows `ErrorBanner` when API is unreachable (not a blank screen)
- [ ] Python processor handles missing log file without crashing

### DevOps Checklist

- [ ] `azure-pipelines.yml` committed and pipeline runs on push
- [ ] All four pipeline stages complete successfully (Build → Test → Validate → Package)
- [ ] Pipeline fails if coverage falls below 80% in any stack
- [ ] `docs/SETUP.md` documents how to run the project locally from scratch
- [ ] `docs/PIPELINE.md` documents Azure DevOps setup steps

---

## NOT in Scope (Explicitly Deferred)

| Item | Rationale |
|---|---|
| OAuth / SSO / JWT | HTTP Basic auth is sufficient for an internal tool; OAuth adds significant complexity |
| WebSocket / Server-Sent Events | 30-second polling achieves the "feels live" goal without new infrastructure |
| Email / Slack / PagerDuty alerting | Out of scope for v1; can be added as a TODO when needed |
| Multi-tenant / multi-user support | Single developer; no access control beyond auth |
| AI/ML anomaly detection | Explicitly excluded from project scope |
| Kubernetes / Docker Compose | Not needed for local dev; add if deploying to shared environment |
| Data archiving beyond 30-day retention | Simple DELETE covers the demo use case; deeper archival is a future concern |
| Frontend search / filter | EventTable shows most recent 50; pagination is sufficient for now |
| `PUT /services` endpoint | Services are seeded via `seed.sql`; status updates deferred |
| Log rotation / compression | Python reads raw `.log` files; rotation is an OS concern |

## What Already Exists

This is a greenfield project. No existing code in the repository.

| Sub-problem | Framework / Library that solves it (no rebuild needed) |
|---|---|
| Paginated REST API | Spring Data `JpaRepository` + `Pageable` — zero custom pagination code |
| Basic auth | Spring Security `HttpSecurity.httpBasic()` — ~20 lines of config |
| CORS | Spring `CorsConfigurationSource` bean — ~15 lines |
| DB upsert | `MERGE` SQL statement — no ORM magic needed |
| Polling in React | `setInterval` in `useEffect` — no library needed |
| Test coverage gate | JaCoCo plugin (Maven), Vitest `--coverage`, `pytest --cov-fail-under` |
| Log file reading | Python `open()` built-in — no library needed |
| Env var loading | `python-dotenv`, Spring `${ENV_VAR}` interpolation |

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 12 issues, 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**VERDICT:** ENG CLEARED — plan reviewed, 12 issues resolved, DESIGN.md written with all decisions incorporated.

NO UNRESOLVED DECISIONS
