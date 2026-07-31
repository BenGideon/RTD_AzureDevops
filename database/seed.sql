-- Sample service records for local development.
-- Run after database/schema.sql.

MERGE dbo.Services AS target
USING (
    VALUES
        ('frontend-dashboard', 'UNKNOWN'),
        ('spring-api', 'UNKNOWN'),
        ('python-log-processor', 'UNKNOWN'),
        ('sql-server-database', 'UNKNOWN')
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
