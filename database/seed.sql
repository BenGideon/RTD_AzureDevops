-- Sample records for local development.
-- Run after database/schema.sql in the same database.

USE [RTD_DB];
GO

IF OBJECT_ID(N'dbo.Services', N'U') IS NULL
    THROW 50001, 'dbo.Services does not exist. Run database/schema.sql in this database first.', 1;

IF OBJECT_ID(N'dbo.Events', N'U') IS NULL
    THROW 50002, 'dbo.Events does not exist. Run database/schema.sql in this database first.', 1;

IF OBJECT_ID(N'dbo.LogAnalysis', N'U') IS NULL
    THROW 50003, 'dbo.LogAnalysis does not exist. Run database/schema.sql in this database first.', 1;
GO

UPDATE target
SET
    current_status = source.current_status,
    last_updated = SYSUTCDATETIME()
FROM dbo.Services AS target
INNER JOIN (
    VALUES
        ('frontend-dashboard', 'UP'),
        ('spring-api', 'UP'),
        ('python-log-processor', 'UP'),
        ('sql-server-database', 'UP')
) AS source (service_name, current_status)
    ON target.service_name = source.service_name;

INSERT INTO dbo.Services (service_name, current_status)
SELECT source.service_name, source.current_status
FROM (
    VALUES
        ('frontend-dashboard', 'UP'),
        ('spring-api', 'UP'),
        ('python-log-processor', 'UP'),
        ('sql-server-database', 'UP')
) AS source (service_name, current_status)
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Services
    WHERE dbo.Services.service_name = source.service_name
);
GO

INSERT INTO dbo.Events (service_name, event_type, severity, message, [timestamp])
SELECT
    source.service_name,
    source.event_type,
    source.severity,
    source.message,
    source.[timestamp]
FROM (
    VALUES
        (
            'spring-api',
            'STARTUP',
            'INFO',
            'Spring Boot API started and connected to SQL Server',
            CONVERT(DATETIME2(0), '2026-07-31T17:00:00')
        ),
        (
            'python-log-processor',
            'LOG_PROCESSING',
            'INFO',
            'Processed sample application log records',
            CONVERT(DATETIME2(0), '2026-07-31T17:01:00')
        ),
        (
            'sql-server-database',
            'DB_CONNECT',
            'INFO',
            'Database connection verified',
            CONVERT(DATETIME2(0), '2026-07-31T17:02:00')
        ),
        (
            'frontend-dashboard',
            'HEALTH_CHECK',
            'WARNING',
            'Dashboard is waiting for the next polling refresh',
            CONVERT(DATETIME2(0), '2026-07-31T17:03:00')
        )
) AS source (service_name, event_type, severity, message, [timestamp])
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Events
    WHERE dbo.Events.service_name = source.service_name
        AND dbo.Events.event_type = source.event_type
        AND dbo.Events.[timestamp] = source.[timestamp]
        AND dbo.Events.message = source.message
);
GO

INSERT INTO dbo.LogAnalysis (file_name, processed_time, records_processed, errors_found)
SELECT
    source.file_name,
    source.processed_time,
    source.records_processed,
    source.errors_found
FROM (
    VALUES
        (
            'sample.log',
            CONVERT(DATETIME2(0), '2026-07-31T17:04:00'),
            4,
            0
        )
) AS source (file_name, processed_time, records_processed, errors_found)
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.LogAnalysis
    WHERE dbo.LogAnalysis.file_name = source.file_name
        AND dbo.LogAnalysis.processed_time = source.processed_time
);
GO
