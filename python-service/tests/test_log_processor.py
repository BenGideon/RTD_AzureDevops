from pathlib import Path

from processor.log_processor import _read_log_file


def test_read_log_file_keeps_valid_entries_and_counts_invalid_entries():
    log_file = Path(__file__).parent / "fixtures" / "mixed.txt"
    events, errors_found = _read_log_file(log_file, "application-log", "LOG_ENTRY")

    assert len(events) == 2
    assert errors_found == 1
    assert events[0].service_name == "application-log"
    assert events[0].entry.message == "Service started"
