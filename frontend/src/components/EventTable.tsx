import { useState } from 'react';
import type { ApplicationEvent } from '../types';
import { EventDetails } from './EventDetails';
import { formatDateTime } from '../utils/format';

interface EventTableProps {
  events: ApplicationEvent[];
}

export function EventTable({ events }: EventTableProps) {
  const [expandedEventId, setExpandedEventId] = useState<number | null>(null);

  return (
    <div className="table-wrap">
      <table className="event-table">
        <thead>
          <tr>
            <th scope="col">Time</th>
            <th scope="col">Service</th>
            <th scope="col">Type</th>
            <th scope="col">Severity</th>
            <th scope="col" aria-label="Details" />
          </tr>
        </thead>
        <tbody>
          {events.map((event) => {
            const isExpanded = expandedEventId === event.id;

            return (
              <tr key={event.id}>
                <td>{formatDateTime(event.timestamp)}</td>
                <td>{event.serviceName}</td>
                <td>{event.eventType}</td>
                <td>
                  <span className={`severity-badge ${event.severity.toLowerCase()}`}>{event.severity}</span>
                </td>
                <td>
                  <button
                    type="button"
                    className="icon-button small"
                    onClick={() => setExpandedEventId(isExpanded ? null : event.id)}
                    aria-label={isExpanded ? 'Hide event details' : 'Show event details'}
                    aria-expanded={isExpanded}
                  >
                    {isExpanded ? '−' : '+'}
                  </button>
                  {isExpanded ? <EventDetails event={event} /> : null}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
