const DEFAULT_API_URL = 'http://localhost:8080';
const DEFAULT_POLL_INTERVAL_MS = 30_000;
const DEFAULT_EVENTS_PAGE_SIZE = 50;

function readPositiveNumber(value: string | undefined, fallback: number): number {
  if (!value) {
    return fallback;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

export const config = {
  apiBaseUrl: (import.meta.env.VITE_API_URL || DEFAULT_API_URL).replace(/\/$/, ''),
  pollIntervalMs: readPositiveNumber(import.meta.env.VITE_POLL_INTERVAL_MS, DEFAULT_POLL_INTERVAL_MS),
  eventsPageSize: readPositiveNumber(import.meta.env.VITE_EVENTS_PAGE_SIZE, DEFAULT_EVENTS_PAGE_SIZE)
};
