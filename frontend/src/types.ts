export type ServiceStatusValue = 'UP' | 'DOWN' | 'UNKNOWN';
export type EventSeverity = 'INFO' | 'WARNING' | 'ERROR';

export interface ServiceStatus {
  id: number;
  serviceName: string;
  currentStatus: ServiceStatusValue;
  lastUpdated: string;
}

export interface ApplicationEvent {
  id: number;
  serviceName: string;
  eventType: string;
  severity: EventSeverity;
  message: string;
  timestamp: string;
}

export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}
