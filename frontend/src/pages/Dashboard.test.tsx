import { render, screen } from '@testing-library/react';
import { Dashboard } from './Dashboard';

vi.mock('../hooks/useDashboardData', () => ({
  useDashboardData: () => ({
    services: [
      {
        id: 1,
        serviceName: 'spring-api',
        currentStatus: 'UP',
        lastUpdated: '2026-07-31T17:00:00'
      }
    ],
    events: [
      {
        id: 1,
        serviceName: 'spring-api',
        eventType: 'HEALTH_CHECK',
        severity: 'INFO',
        message: 'API health check passed',
        timestamp: '2026-07-31T17:00:00'
      }
    ],
    isLoading: false,
    error: null,
    lastUpdated: new Date('2026-07-31T17:00:00'),
    refresh: vi.fn()
  })
}));

describe('Dashboard', () => {
  it('renders service status and events', () => {
    render(<Dashboard />);

    expect(screen.getByRole('heading', { name: 'Automation Dashboard' })).toBeInTheDocument();
    expect(screen.getAllByText('spring-api')).toHaveLength(2);
    expect(screen.getByText('HEALTH_CHECK')).toBeInTheDocument();
  });
});
