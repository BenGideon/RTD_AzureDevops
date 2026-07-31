-- Sample service records for local development.
-- Run after database/schema.sql.

MERGE dbo.Services AS target
USING (
    VALUES
        ('frontend-dashboard', 'UP'),
        ('spring-api', 'UP'),
        ('python-log-processor', 'UP'),
        ('sql-server-database', 'UP')
) AS source (service_name, current_status)
ON target.service_name = source.service_name
WHEN NOT MATCHED THEN
    INSERT (service_name, current_status)
    VALUES (source.service_name, source.current_status)
WHEN MATCHED THEN
    UPDATE SET
        current_status = source.current_status,
        last_updated = SYSUTCDATETIME();
GO

MERGE dbo.Events AS target
USING (
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
ON target.service_name = source.service_name
    AND target.event_type = source.event_type
    AND target.[timestamp] = source.[timestamp]
    AND target.message = source.message
WHEN NOT MATCHED THEN
    INSERT (service_name, event_type, severity, message, [timestamp])
    VALUES (
        source.service_name,
        source.event_type,
        source.severity,
        source.message,
        source.[timestamp]
    );
GO

MERGE dbo.LogAnalysis AS target
USING (
    VALUES
        (
            'sample.log',
            CONVERT(DATETIME2(0), '2026-07-31T17:04:00'),
            4,
            0
        )
) AS source (file_name, processed_time, records_processed, errors_found)
ON target.file_name = source.file_name
    AND target.processed_time = source.processed_time
WHEN NOT MATCHED THEN
    INSERT (file_name, processed_time, records_processed, errors_found)
    VALUES (
        source.file_name,
        source.processed_time,
        source.records_processed,
        source.errors_found
    );
GO
