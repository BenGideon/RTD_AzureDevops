from collections.abc import Iterable
from dataclasses import dataclass

from validator.log_validator import ParsedLogEntry


@dataclass(frozen=True)
class EventRecord:
    service_name: str
    event_type: str
    entry: ParsedLogEntry


class DatabaseWriter:
    def __init__(self, connection_string: str) -> None:
        self.connection_string = connection_string

    def _connect(self):
        import pyodbc

        return pyodbc.connect(self.connection_string)

    def cleanup_old_events(self, retention_days: int) -> None:
        with self._connect() as connection:
            cursor = connection.cursor()
            cursor.execute(
                """
                DELETE FROM dbo.Events
                WHERE [timestamp] < DATEADD(day, ?, SYSUTCDATETIME())
                """,
                -retention_days,
            )
            connection.commit()

    def insert_events(self, events: Iterable[EventRecord]) -> int:
        inserted = 0
        with self._connect() as connection:
            cursor = connection.cursor()
            for event in events:
                cursor.execute(
                    """
                    MERGE dbo.Events AS target
                    USING (
                        SELECT
                            ? AS service_name,
                            ? AS event_type,
                            ? AS severity,
                            ? AS message,
                            ? AS [timestamp]
                    ) AS source
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
                    """,
                    event.service_name,
                    event.event_type,
                    event.entry.severity,
                    event.entry.message,
                    event.entry.timestamp,
                )
                inserted += cursor.rowcount if cursor.rowcount and cursor.rowcount > 0 else 0
            connection.commit()
        return inserted

    def write_log_analysis(
        self,
        file_name: str,
        records_processed: int,
        errors_found: int,
    ) -> None:
        with self._connect() as connection:
            cursor = connection.cursor()
            cursor.execute(
                """
                INSERT INTO dbo.LogAnalysis (file_name, records_processed, errors_found)
                VALUES (?, ?, ?)
                """,
                file_name,
                records_processed,
                errors_found,
            )
            connection.commit()
