from pathlib import Path
import random


BASE_DIR = Path(__file__).resolve().parent
LOG_DIR = BASE_DIR / "logs"
SAMPLE_LOG = LOG_DIR / "sample.log"

MESSAGES = [
    ("INFO", "Service started"),
    ("INFO", "Health check passed"),
    ("WARNING", "Response delay detected"),
    ("ERROR", "Database failed"),
    ("INFO", "Background task completed"),
]


def generate_sample_log(line_count: int = 50) -> Path:
    random.seed(31)
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    with SAMPLE_LOG.open("w", encoding="utf-8") as file:
        for _ in range(line_count):
            severity, message = random.choice(MESSAGES)
            file.write(f"{severity} 2026-07-31 {message}\n")

        file.write("INVALID LINE WITHOUT EXPECTED FORMAT\n")

    return SAMPLE_LOG


if __name__ == "__main__":
    path = generate_sample_log()
    print(f"Generated {path}")
