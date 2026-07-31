from datetime import datetime

from validator.log_validator import parse_line


def test_valid_log_line_is_accepted():
    parsed = parse_line("INFO 2026-07-31 Service started")

    assert parsed is not None
    assert parsed.severity == "INFO"
    assert parsed.timestamp == datetime(2026, 7, 31)
    assert parsed.message == "Service started"


def test_invalid_log_line_is_rejected():
    assert parse_line("not a valid log entry") is None
