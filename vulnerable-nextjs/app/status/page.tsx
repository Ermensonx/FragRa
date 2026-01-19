import Link from 'next/link'

export default function StatusPage() {
    const services = [
        { name: 'API Gateway', status: 'operational', uptime: '99.99%', latency: '12ms' },
        { name: 'Web Dashboard', status: 'operational', uptime: '99.99%', latency: '45ms' },
        { name: 'Container Runtime', status: 'operational', uptime: '99.98%', latency: '8ms' },
        { name: 'Object Storage', status: 'operational', uptime: '99.99%', latency: '23ms' },
        { name: 'Database Clusters', status: 'operational', uptime: '99.97%', latency: '5ms' },
        { name: 'CDN Edge Network', status: 'operational', uptime: '100%', latency: '2ms' },
        { name: 'DNS Services', status: 'operational', uptime: '100%', latency: '1ms' },
        { name: 'SSL Certificates', status: 'operational', uptime: '99.99%', latency: '15ms' },
    ]

    const incidents = [
        {
            date: 'Dec 28, 2024',
            title: 'Increased latency in US-East region',
            status: 'resolved',
            description: 'Some users experienced elevated latency. Issue was identified and resolved.'
        },
        {
            date: 'Dec 15, 2024',
            title: 'Dashboard login issues',
            status: 'resolved',
            description: 'OAuth provider experienced intermittent issues. Fallback authentication enabled.'
        },
    ]

    return (
        <>
            <nav className="navbar">
                <div className="container navbar-content">
                    <Link href="/" className="navbar-brand">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" />
                        </svg>
                        Cloud Fragment
                    </Link>

                    <div className="navbar-links">
                        <Link href="/features" className="navbar-link">Features</Link>
                        <Link href="/pricing" className="navbar-link">Pricing</Link>
                        <Link href="/docs" className="navbar-link">Documentation</Link>
                        <Link href="/status" className="navbar-link" style={{ color: 'var(--accent)' }}>Status</Link>
                    </div>

                    <div style={{ display: 'flex', gap: '1rem' }}>
                        <Link href="/login" className="btn btn-ghost">Sign In</Link>
                        <Link href="/register" className="btn btn-primary">Get Started</Link>
                    </div>
                </div>
            </nav>

            <section className="hero" style={{ paddingBottom: '2rem' }}>
                <div className="container">
                    <div style={{ display: 'inline-flex', alignItems: 'center', gap: '0.75rem', background: 'rgba(34, 197, 94, 0.1)', padding: '0.75rem 1.5rem', borderRadius: '9999px', marginBottom: '2rem' }}>
                        <span style={{ width: '12px', height: '12px', background: 'var(--accent)', borderRadius: '50%', animation: 'pulse 2s infinite' }}></span>
                        <span style={{ color: 'var(--accent)', fontWeight: '600' }}>All Systems Operational</span>
                    </div>
                    <h1>System Status</h1>
                    <p>Real-time status of Cloud Fragment services</p>
                </div>
            </section>

            <section className="container" style={{ paddingBottom: '3rem' }}>
                <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                    <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)' }}>
                        <h2 style={{ fontSize: '1.25rem' }}>Current Status</h2>
                    </div>
                    <table className="table">
                        <thead>
                            <tr>
                                <th>Service</th>
                                <th>Status</th>
                                <th>Uptime (30d)</th>
                                <th>Latency</th>
                            </tr>
                        </thead>
                        <tbody>
                            {services.map((service, idx) => (
                                <tr key={idx}>
                                    <td style={{ fontWeight: '500' }}>{service.name}</td>
                                    <td>
                                        <span className="badge badge-success" style={{ textTransform: 'capitalize' }}>
                                            {service.status}
                                        </span>
                                    </td>
                                    <td style={{ color: 'var(--accent)' }}>{service.uptime}</td>
                                    <td style={{ color: 'var(--text-secondary)' }}>{service.latency}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </section>

            <section className="container" style={{ paddingBottom: '3rem' }}>
                <h2 style={{ marginBottom: '1.5rem' }}>Uptime History (90 days)</h2>
                <div className="card" style={{ padding: '1.5rem' }}>
                    <div style={{ display: 'flex', gap: '2px', marginBottom: '1rem' }}>
                        {[...Array(90)].map((_, i) => (
                            <div
                                key={i}
                                style={{
                                    flex: 1,
                                    height: '32px',
                                    background: i === 62 || i === 75 ? 'var(--warning)' : 'var(--accent)',
                                    borderRadius: '2px',
                                    opacity: 0.8
                                }}
                                title={`Day ${90 - i}`}
                            />
                        ))}
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                        <span>90 days ago</span>
                        <span>Today</span>
                    </div>
                </div>
            </section>

            <section className="container" style={{ paddingBottom: '4rem' }}>
                <h2 style={{ marginBottom: '1.5rem' }}>Past Incidents</h2>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    {incidents.map((incident, idx) => (
                        <div key={idx} className="card" style={{ padding: '1.5rem' }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
                                <h3 style={{ fontSize: '1rem' }}>{incident.title}</h3>
                                <span className="badge badge-success">{incident.status}</span>
                            </div>
                            <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>
                                {incident.description}
                            </p>
                            <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>{incident.date}</span>
                        </div>
                    ))}
                </div>
            </section>

            <section className="container" style={{ paddingBottom: '4rem' }}>
                <div className="card" style={{ textAlign: 'center', padding: '2rem' }}>
                    <h3 style={{ marginBottom: '0.5rem' }}>Subscribe to Status Updates</h3>
                    <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem', fontSize: '0.875rem' }}>
                        Get notified when incidents occur
                    </p>
                    <div style={{ display: 'flex', gap: '0.5rem', maxWidth: '400px', margin: '0 auto' }}>
                        <input type="email" className="form-input" placeholder="Enter your email" />
                        <button className="btn btn-primary">Subscribe</button>
                    </div>
                </div>
            </section>

            <footer className="footer">
                <div className="container">
                    <p>© 2024 Cloud Fragment. All rights reserved.</p>
                </div>
            </footer>
        </>
    )
}
