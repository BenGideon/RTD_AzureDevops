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

IF COL_LENGTH(N'dbo.Services', N'service_name') IS NULL
    THROW 50011, 'dbo.Services.service_name is missing. Re-run database/schema.sql against RTD_DB.', 1;

IF COL_LENGTH(N'dbo.Services', N'current_status') IS NULL
    THROW 50012, 'dbo.Services.current_status is missing. Re-run database/schema.sql against RTD_DB.', 1;

IF COL_LENGTH(N'dbo.Services', N'last_updated') IS NULL
    THROW 50013, 'dbo.Services.last_updated is missing. Re-run database/schema.sql against RTD_DB.', 1;

IF COL_LENGTH(N'dbo.Events', N'service_name') IS NULL
    THROW 50021, 'dbo.Events.service_name is missing. Re-run database/schema.sql against RTD_DB.', 1;

IF COL_LENGTH(N'dbo.Events', N'event_type') IS NULL
    THROW 50022, 'dbo.Events.event_type is missing. Re-run database/schema.sql against RTD_DB.', 1;

IF COL_LENGTH(N'dbo.Events', N'severity') IS NULL
    THROW 50023, 'dbo.Events.severity is missing. Re-run database/schema.sql against RTD_DB.', 1;

IF COL_LENGTH(N'dbo.Events', N'message') IS NULL
    THROW 50024, 'dbo.Events.message is missing. Re-run database/schema.sql against RTD_DB.', 1;

IF COL_LENGTH(N'dbo.Events', N'timestamp') IS NULL
    THROW 50025, 'dbo.Events.timestamp is missing. Re-run database/schema.sql against RTD_DB.', 1;

IF COL_LENGTH(N'dbo.LogAnalysis', N'file_name') IS NULL
    THROW 50031, 'dbo.LogAnalysis.file_name is missing. Re-run database/schema.sql against RTD_DB.', 1;

IF COL_LENGTH(N'dbo.LogAnalysis', N'processed_time') IS NULL
    THROW 50032, 'dbo.LogAnalysis.processed_time is missing. Re-run database/schema.sql against RTD_DB.', 1;

IF COL_LENGTH(N'dbo.LogAnalysis', N'records_processed') IS NULL
    THROW 50033, 'dbo.LogAnalysis.records_processed is missing. Re-run database/schema.sql against RTD_DB.', 1;

IF COL_LENGTH(N'dbo.LogAnalysis', N'errors_found') IS NULL
    THROW 50034, 'dbo.LogAnalysis.errors_found is missing. Re-run database/schema.sql against RTD_DB.', 1;
GO

EXEC sys.sp_executesql N'
UPDATE target
SET
    current_status = source.current_status,
    last_updated = SYSUTCDATETIME()
FROM dbo.Services AS target
INNER JOIN (
    VALUES
        (''frontend-dashboard'', ''UP''),
        (''spring-api'', ''UP''),
        (''python-log-processor'', ''UP''),
        (''sql-server-database'', ''UP'')
) AS source (service_name, current_status)
    ON target.service_name = source.service_name;
';

EXEC sys.sp_executesql N'
INSERT INTO dbo.Services (service_name, current_status)
SELECT source.service_name, source.current_status
FROM (
    VALUES
        (''frontend-dashboard'', ''UP''),
        (''spring-api'', ''UP''),
        (''python-log-processor'', ''UP''),
        (''sql-server-database'', ''UP'')
) AS source (service_name, current_status)
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Services
    WHERE dbo.Services.service_name = source.service_name
);
';
GO

EXEC sys.sp_executesql N'
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
            ''spring-api'',
            ''STARTUP'',
            ''INFO'',
            ''Spring Boot API started and connected to SQL Server'',
            CONVERT(DATETIME2(0), ''2026-07-31T17:00:00'')
        ),
        (
            ''python-log-processor'',
            ''LOG_PROCESSING'',
            ''INFO'',
            ''Processed sample application log records'',
            CONVERT(DATETIME2(0), ''2026-07-31T17:01:00'')
        ),
        (
            ''sql-server-database'',
            ''DB_CONNECT'',
            ''INFO'',
            ''Database connection verified'',
            CONVERT(DATETIME2(0), ''2026-07-31T17:02:00'')
        ),
        (
            ''frontend-dashboard'',
            ''HEALTH_CHECK'',
            ''WARNING'',
            ''Dashboard is waiting for the next polling refresh'',
            CONVERT(DATETIME2(0), ''2026-07-31T17:03:00'')
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
';
GO

EXEC sys.sp_executesql N'
INSERT INTO dbo.LogAnalysis (file_name, processed_time, records_processed, errors_found)
SELECT
    source.file_name,
    source.processed_time,
    source.records_processed,
    source.errors_found
FROM (
    VALUES
        (
            ''sample.log'',
            CONVERT(DATETIME2(0), ''2026-07-31T17:04:00''),
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
';
GO
