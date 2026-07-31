import type { ApplicationEvent, PageResponse, ServiceStatus } from '../types';
import { config } from '../config';

async function getJson<T>(path: string): Promise<T> {
  const response = await fetch(`${config.apiBaseUrl}${path}`);

  if (!response.ok) {
    throw new Error(`API request failed: ${response.status} ${response.statusText}`);
  }

  return response.json() as Promise<T>;
}

export function getServices(): Promise<ServiceStatus[]> {
  return getJson<ServiceStatus[]>('/api/services');
}

export function getEvents(): Promise<PageResponse<ApplicationEvent>> {
  return getJson<PageResponse<ApplicationEvent>>(`/api/events?page=0&size=${config.eventsPageSize}`);
}
