import type { ApplicationEvent } from '../types';

interface EventDetailsProps {
  event: ApplicationEvent;
}

export function EventDetails({ event }: EventDetailsProps) {
  return (
    <div className="event-details">
      <dl>
        <div>
          <dt>Message</dt>
          <dd>{event.message}</dd>
        </div>
        <div>
          <dt>Event ID</dt>
          <dd>{event.id}</dd>
        </div>
      </dl>
    </div>
  );
}
