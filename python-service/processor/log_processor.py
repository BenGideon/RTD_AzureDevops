from datetime import datetime
from pathlib import Path
import sys

from config.config import load_settings
from processor.database_writer import DatabaseWriter, EventRecord
from validator.log_validator import parse_line


def _write_scheduler_log(log_dir: Path, message: str) -> None:
    log_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with (log_dir / "scheduler.log").open("a", encoding="utf-8") as log_file:
        log_file.write(f"{timestamp} {message}\n")


def _read_log_file(path: Path, default_service_name: str, default_event_type: str) -> tuple[list[EventRecord], int]:
    events: list[EventRecord] = []
    errors_found = 0

    with path.open("r", encoding="utf-8") as file:
        for line_number, line in enumerate(file, start=1):
            parsed = parse_line(line)
            if parsed is None:
                errors_found += 1
                continue

            events.append(
                EventRecord(
                    service_name=default_service_name,
                    event_type=default_event_type,
                    entry=parsed,
                )
            )

    return events, errors_found


def process_logs() -> int:
    settings = load_settings()
    settings.log_dir.mkdir(parents=True, exist_ok=True)
    log_files = sorted(
        path for path in settings.log_dir.glob("*.log") if path.name != "scheduler.log"
    )

    if not log_files:
        _write_scheduler_log(settings.log_dir, "No application log files found.")
        return 0

    writer = DatabaseWriter(settings.connection_string)

    try:
        writer.cleanup_old_events(settings.retention_days)
    except Exception as exc:
        _write_scheduler_log(settings.log_dir, f"Database cleanup failed: {exc}")
        return 1

    for log_file in log_files:
        events, errors_found = _read_log_file(
            log_file,
            settings.default_service_name,
            settings.default_event_type,
        )

        try:
            inserted = writer.insert_events(events)
            writer.write_log_analysis(log_file.name, len(events), errors_found)
        except Exception as exc:
            _write_scheduler_log(settings.log_dir, f"{log_file.name}: database write failed: {exc}")
            return 1

        _write_scheduler_log(
            settings.log_dir,
            (
                f"{log_file.name}: valid={len(events)} "
                f"invalid={errors_found} inserted={inserted}"
            ),
        )

    return 0


if __name__ == "__main__":
    sys.exit(process_logs())
