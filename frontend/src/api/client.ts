import type { ApplicationEvent, PageResponse, ServiceStatus } from '../types';

const apiBaseUrl = import.meta.env.VITE_API_URL ?? 'http://localhost:8080';

async function getJson<T>(path: string): Promise<T> {
  const response = await fetch(`${apiBaseUrl}${path}`);

  if (!response.ok) {
    throw new Error(`API request failed with status ${response.status}`);
  }

  return response.json() as Promise<T>;
}

export function getServices(): Promise<ServiceStatus[]> {
  return getJson<ServiceStatus[]>('/api/services');
}

export function getEvents(): Promise<PageResponse<ApplicationEvent>> {
  return getJson<PageResponse<ApplicationEvent>>('/api/events?page=0&size=50');
}
