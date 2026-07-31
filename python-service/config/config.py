from dataclasses import dataclass
import os
from pathlib import Path

from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parents[1]
load_dotenv(BASE_DIR / ".env")


@dataclass(frozen=True)
class Settings:
    db_server: str
    db_name: str
    db_user: str
    db_password: str
    db_driver: str
    db_trusted_connection: bool
    log_dir: Path
    default_service_name: str
    default_event_type: str
    retention_days: int
    log_level: str

    @property
    def connection_string(self) -> str:
        base = (
            f"DRIVER={{{self.db_driver}}};"
            f"SERVER={self.db_server};"
            f"DATABASE={self.db_name};"
            "Encrypt=yes;"
            "TrustServerCertificate=yes;"
        )

        if self.db_trusted_connection:
            return base + "Trusted_Connection=yes;"

        return base + f"UID={self.db_user};PWD={self.db_password};"


def _get_bool(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "y"}


def _required(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def _get_positive_int(name: str, default: int) -> int:
    value = os.getenv(name)
    if value is None:
        return default

    try:
        parsed = int(value)
    except ValueError as exc:
        raise RuntimeError(f"{name} must be an integer") from exc

    if parsed <= 0:
        raise RuntimeError(f"{name} must be greater than zero")

    return parsed


def _get_log_dir() -> Path:
    raw_value = os.getenv("LOG_DIR", "logs")
    path = Path(raw_value)
    return path if path.is_absolute() else BASE_DIR / path


def load_settings() -> Settings:
    trusted_connection = _get_bool("DB_TRUSTED_CONNECTION")

    return Settings(
        db_server=_required("DB_SERVER"),
        db_name=_required("DB_NAME"),
        db_user="" if trusted_connection else _required("DB_USER"),
        db_password="" if trusted_connection else _required("DB_PASSWORD"),
        db_driver=os.getenv("DB_DRIVER", "ODBC Driver 18 for SQL Server"),
        db_trusted_connection=trusted_connection,
        log_dir=_get_log_dir(),
        default_service_name=os.getenv("DEFAULT_SERVICE_NAME", "application-log"),
        default_event_type=os.getenv("DEFAULT_EVENT_TYPE", "LOG_ENTRY"),
        retention_days=_get_positive_int("RETENTION_DAYS", 30),
        log_level=os.getenv("LOG_LEVEL", "INFO"),
    )
