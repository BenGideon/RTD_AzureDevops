import { EventTable } from '../components/EventTable';
import { ServiceStatus } from '../components/ServiceStatus';
import { useDashboardData } from '../hooks/useDashboardData';

export function Dashboard() {
  const { services, events, isLoading, error, lastUpdated, refresh } = useDashboardData();

  return (
    <main className="app-shell">
      <header className="dashboard-header">
        <div>
          <p className="eyebrow">Process Monitoring</p>
          <h1>Automation Dashboard</h1>
        </div>
        <div className="refresh-summary">
          <span>{lastUpdated ? `Updated ${lastUpdated.toLocaleTimeString()}` : 'Waiting for data'}</span>
          <button type="button" className="icon-button" onClick={() => void refresh()} aria-label="Refresh dashboard">
            ↻
          </button>
        </div>
      </header>

      {error ? <div className="error-banner">{error}</div> : null}

      {isLoading ? (
        <section className="state-panel">Loading dashboard data...</section>
      ) : (
        <>
          <section className="section">
            <div className="section-heading">
              <h2>Service Status</h2>
              <span>{services.length} services</span>
            </div>
            {services.length > 0 ? (
              <div className="status-grid">
                {services.map((service) => (
                  <ServiceStatus key={service.id} service={service} />
                ))}
              </div>
            ) : (
              <div className="state-panel">No services found.</div>
            )}
          </section>

          <section className="section">
            <div className="section-heading">
              <h2>Recent Events</h2>
              <span>{events.length} displayed</span>
            </div>
            {events.length > 0 ? <EventTable events={events} /> : <div className="state-panel">No events found.</div>}
          </section>
        </>
      )}
    </main>
  );
}
