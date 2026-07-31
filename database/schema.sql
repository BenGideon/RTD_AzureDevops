-- SQL Server schema for the Process Monitoring & Automation Dashboard.
-- This script creates the three core tables used by the backend API,
-- dashboard, and Python log processor.

IF OBJECT_ID('dbo.LogAnalysis', 'U') IS NOT NULL
    DROP TABLE dbo.LogAnalysis;

IF OBJECT_ID('dbo.Events', 'U') IS NOT NULL
    DROP TABLE dbo.Events;

IF OBJECT_ID('dbo.Services', 'U') IS NOT NULL
    DROP TABLE dbo.Services;
GO

CREATE TABLE dbo.Services (
    id INT IDENTITY(1,1) NOT NULL,
    service_name NVARCHAR(100) NOT NULL,
    current_status NVARCHAR(10) NOT NULL
        CONSTRAINT DF_Services_current_status DEFAULT ('UNKNOWN'),
    last_updated DATETIME2(0) NOT NULL
        CONSTRAINT DF_Services_last_updated DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Services PRIMARY KEY CLUSTERED (id),
    CONSTRAINT UQ_Services_service_name UNIQUE (service_name),
    CONSTRAINT CK_Services_current_status
        CHECK (current_status IN ('UP', 'DOWN', 'UNKNOWN'))
);
GO

CREATE TABLE dbo.Events (
    id INT IDENTITY(1,1) NOT NULL,
    service_name NVARCHAR(100) NOT NULL,
    event_type NVARCHAR(50) NOT NULL,
    severity NVARCHAR(10) NOT NULL,
    message NVARCHAR(500) NOT NULL,
    [timestamp] DATETIME2(0) NOT NULL,

    CONSTRAINT PK_Events PRIMARY KEY CLUSTERED (id),
    CONSTRAINT CK_Events_severity
        CHECK (severity IN ('INFO', 'WARNING', 'ERROR')),
    CONSTRAINT UQ_Events_dedup
        UNIQUE (service_name, event_type, [timestamp], message)
);
GO

CREATE TABLE dbo.LogAnalysis (
    id INT IDENTITY(1,1) NOT NULL,
    file_name NVARCHAR(260) NOT NULL,
    processed_time DATETIME2(0) NOT NULL
        CONSTRAINT DF_LogAnalysis_processed_time DEFAULT (SYSUTCDATETIME()),
    records_processed INT NOT NULL
        CONSTRAINT DF_LogAnalysis_records_processed DEFAULT (0),
    errors_found INT NOT NULL
        CONSTRAINT DF_LogAnalysis_errors_found DEFAULT (0),

    CONSTRAINT PK_LogAnalysis PRIMARY KEY CLUSTERED (id),
    CONSTRAINT CK_LogAnalysis_records_processed
        CHECK (records_processed >= 0),
    CONSTRAINT CK_LogAnalysis_errors_found
        CHECK (errors_found >= 0)
);
GO

CREATE NONCLUSTERED INDEX IX_Events_timestamp
    ON dbo.Events ([timestamp] DESC);

CREATE NONCLUSTERED INDEX IX_Events_severity
    ON dbo.Events (severity);

CREATE NONCLUSTERED INDEX IX_Events_service_name
    ON dbo.Events (service_name);

CREATE NONCLUSTERED INDEX IX_LogAnalysis_processed_time
    ON dbo.LogAnalysis (processed_time DESC);
GO
