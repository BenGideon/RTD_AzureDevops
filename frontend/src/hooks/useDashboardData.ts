import { useCallback, useEffect, useState } from 'react';
import { getEvents, getServices } from '../api/client';
import type { ApplicationEvent, ServiceStatus } from '../types';

const POLL_INTERVAL_MS = 30_000;

interface DashboardData {
  services: ServiceStatus[];
  events: ApplicationEvent[];
  isLoading: boolean;
  error: string | null;
  lastUpdated: Date | null;
  refresh: () => Promise<void>;
}

export function useDashboardData(): DashboardData {
  const [services, setServices] = useState<ServiceStatus[]>([]);
  const [events, setEvents] = useState<ApplicationEvent[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);

  const refresh = useCallback(async () => {
    try {
      const [serviceData, eventPage] = await Promise.all([getServices(), getEvents()]);
      setServices(serviceData);
      setEvents(eventPage.content);
      setError(null);
      setLastUpdated(new Date());
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to load dashboard data');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void refresh();
    const intervalId = window.setInterval(() => {
      void refresh();
    }, POLL_INTERVAL_MS);

    return () => window.clearInterval(intervalId);
  }, [refresh]);

  return { services, events, isLoading, error, lastUpdated, refresh };
}
