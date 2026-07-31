from dataclasses import dataclass
from datetime import datetime
import re


LOG_PATTERN = re.compile(
    r"^(?P<severity>INFO|WARNING|ERROR)\s+"
    r"(?P<date>\d{4}-\d{2}-\d{2})"
    r"(?:\s+(?P<time>\d{2}:\d{2}:\d{2}))?"
    r"\s+(?P<message>.+)$"
)


@dataclass(frozen=True)
class ParsedLogEntry:
    severity: str
    timestamp: datetime
    message: str


def parse_line(line: str) -> ParsedLogEntry | None:
    match = LOG_PATTERN.match(line.strip())
    if not match:
        return None

    timestamp_value = match.group("date")
    if match.group("time"):
        timestamp_value = f"{timestamp_value} {match.group('time')}"
        timestamp_format = "%Y-%m-%d %H:%M:%S"
    else:
        timestamp_format = "%Y-%m-%d"

    try:
        timestamp = datetime.strptime(timestamp_value, timestamp_format)
    except ValueError:
        return None

    message = match.group("message").strip()
    if not message:
        return None

    return ParsedLogEntry(
        severity=match.group("severity"),
        timestamp=timestamp,
        message=message,
    )
