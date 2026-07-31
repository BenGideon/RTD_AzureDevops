import { render, screen } from '@testing-library/react';
import { EventTable } from './EventTable';
import type { ApplicationEvent } from '../types';

const events: ApplicationEvent[] = [
  {
    id: 1,
    serviceName: 'spring-api',
    eventType: 'HEALTH_CHECK',
    severity: 'INFO',
    message: 'API health check passed',
    timestamp: '2026-07-31T17:00:00'
  }
];

describe('EventTable', () => {
  it('displays recent events', () => {
    render(<EventTable events={events} />);

    expect(screen.getByText('spring-api')).toBeInTheDocument();
    expect(screen.getByText('HEALTH_CHECK')).toBeInTheDocument();
    expect(screen.getByText('INFO')).toBeInTheDocument();
  });
});
