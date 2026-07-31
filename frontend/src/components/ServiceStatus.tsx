import type { ServiceStatus as ServiceStatusType } from '../types';
import { formatDateTime } from '../utils/format';

interface ServiceStatusProps {
  service: ServiceStatusType;
}

export function ServiceStatus({ service }: ServiceStatusProps) {
  const statusClass = service.currentStatus.toLowerCase();

  return (
    <article className="status-card">
      <div className="status-card-header">
        <h3>{service.serviceName}</h3>
        <span className={`status-pill ${statusClass}`}>{service.currentStatus}</span>
      </div>
      <p>Last updated {formatDateTime(service.lastUpdated)}</p>
    </article>
  );
}
