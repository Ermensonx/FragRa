import Link from 'next/link'

export default function AnalyticsPage() {
    return (
        <>
            <nav className="navbar">
                <div className="container navbar-content">
                    <Link href="/" className="navbar-brand">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ color: 'var(--accent)' }}>
                            <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" />
                        </svg>
                        Cloud Fragment
                    </Link>

                    <div className="navbar-links">
                        <Link href="/dashboard" className="navbar-link">Projects</Link>
                        <Link href="/dashboard/deployments" className="navbar-link">Deployments</Link>
                        <Link href="/dashboard/analytics" className="navbar-link" style={{ color: 'var(--accent)' }}>Analytics</Link>
                        <Link href="/dashboard/settings" className="navbar-link">Settings</Link>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                        <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: 'var(--accent)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '600', fontSize: '0.875rem' }}>
                            JD
                        </div>
                    </div>
                </div>
            </nav>

            <div className="container dashboard">
                <div className="dashboard-header">
                    <div>
                        <h1 className="dashboard-title">Analytics</h1>
                        <p style={{ color: 'var(--text-secondary)', marginTop: '0.25rem' }}>
                            Monitor performance and usage metrics
                        </p>
                    </div>
                    <div style={{ display: 'flex', gap: '1rem' }}>
                        <select className="form-input" style={{ width: 'auto' }}>
                            <option>Last 24 hours</option>
                            <option>Last 7 days</option>
                            <option>Last 30 days</option>
                            <option>Last 90 days</option>
                        </select>
                        <button className="btn btn-secondary">Export</button>
                    </div>
                </div>

                {/* Key Metrics */}
                <div className="stats-grid" style={{ marginBottom: '2rem' }}>
                    <div className="card" style={{ padding: '1.5rem' }}>
                        <div style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Total Requests</div>
                        <div style={{ fontSize: '2rem', fontWeight: '700' }}>1.2M</div>
                        <div style={{ fontSize: '0.875rem', color: 'var(--accent)' }}>↑ 12% from yesterday</div>
                    </div>
                    <div className="card" style={{ padding: '1.5rem' }}>
                        <div style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Avg Response Time</div>
                        <div style={{ fontSize: '2rem', fontWeight: '700' }}>45ms</div>
                        <div style={{ fontSize: '0.875rem', color: 'var(--accent)' }}>↓ 8% from yesterday</div>
                    </div>
                    <div className="card" style={{ padding: '1.5rem' }}>
                        <div style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Error Rate</div>
                        <div style={{ fontSize: '2rem', fontWeight: '700' }}>0.02%</div>
                        <div style={{ fontSize: '0.875rem', color: 'var(--accent)' }}>↓ 5% from yesterday</div>
                    </div>
                    <div className="card" style={{ padding: '1.5rem' }}>
                        <div style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Bandwidth Used</div>
                        <div style={{ fontSize: '2rem', fontWeight: '700' }}>48.2 GB</div>
                        <div style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>of 1 TB (4.8%)</div>
                    </div>
                </div>

                {/* Traffic Chart Placeholder */}
                <div className="card" style={{ marginBottom: '2rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                        <h2 style={{ fontSize: '1.125rem' }}>Traffic Overview</h2>
                        <div style={{ display: 'flex', gap: '1rem' }}>
                            <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem' }}>
                                <span style={{ width: '12px', height: '12px', background: 'var(--accent)', borderRadius: '2px' }}></span>
                                Requests
                            </span>
                            <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem' }}>
                                <span style={{ width: '12px', height: '12px', background: 'var(--warning)', borderRadius: '2px' }}></span>
                                Errors
                            </span>
                        </div>
                    </div>
                    <div style={{ height: '200px', display: 'flex', alignItems: 'flex-end', gap: '4px', padding: '0 1rem' }}>
                        {[65, 45, 78, 52, 89, 67, 45, 92, 56, 78, 45, 67, 89, 76, 54, 87, 65, 78, 92, 45, 67, 89, 76].map((h, i) => (
                            <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '2px' }}>
                                <div style={{ height: `${h * 1.8}px`, background: 'var(--accent)', borderRadius: '2px 2px 0 0', opacity: 0.8 }}></div>
                                <div style={{ height: `${Math.random() * 5}px`, background: 'var(--warning)', borderRadius: '0 0 2px 2px', opacity: 0.8 }}></div>
                            </div>
                        ))}
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', padding: '1rem 1rem 0', fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                        <span>00:00</span>
                        <span>06:00</span>
                        <span>12:00</span>
                        <span>18:00</span>
                        <span>24:00</span>
                    </div>
                </div>

                {/* Top Endpoints & Regions */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>
                    <div className="card">
                        <h2 style={{ fontSize: '1.125rem', marginBottom: '1.5rem' }}>Top Endpoints</h2>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                            {[
                                { path: '/api/v1/users', requests: '245K', pct: 85 },
                                { path: '/api/v1/auth/login', requests: '189K', pct: 65 },
                                { path: '/api/v1/products', requests: '156K', pct: 54 },
                                { path: '/api/v1/orders', requests: '98K', pct: 34 },
                                { path: '/api/v1/payments', requests: '67K', pct: 23 },
                            ].map((ep, i) => (
                                <div key={i}>
                                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                                        <code style={{ fontSize: '0.875rem' }}>{ep.path}</code>
                                        <span style={{ color: 'var(--text-secondary)', fontSize: '0.875rem' }}>{ep.requests}</span>
                                    </div>
                                    <div style={{ height: '4px', background: 'var(--bg-secondary)', borderRadius: '2px' }}>
                                        <div style={{ width: `${ep.pct}%`, height: '100%', background: 'var(--accent)', borderRadius: '2px' }}></div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>

                    <div className="card">
                        <h2 style={{ fontSize: '1.125rem', marginBottom: '1.5rem' }}>Traffic by Region</h2>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                            {[
                                { region: 'North America', requests: '456K', pct: 78, flag: '🇺🇸' },
                                { region: 'Europe', requests: '312K', pct: 53, flag: '🇪🇺' },
                                { region: 'Asia Pacific', requests: '234K', pct: 40, flag: '🇯🇵' },
                                { region: 'South America', requests: '123K', pct: 21, flag: '🇧🇷' },
                                { region: 'Other', requests: '75K', pct: 13, flag: '🌍' },
                            ].map((r, i) => (
                                <div key={i}>
                                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                                        <span style={{ fontSize: '0.875rem' }}>{r.flag} {r.region}</span>
                                        <span style={{ color: 'var(--text-secondary)', fontSize: '0.875rem' }}>{r.requests}</span>
                                    </div>
                                    <div style={{ height: '4px', background: 'var(--bg-secondary)', borderRadius: '2px' }}>
                                        <div style={{ width: `${r.pct}%`, height: '100%', background: 'var(--accent)', borderRadius: '2px' }}></div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            </div>
            {/* Hidden Dev Hint */}
            <div style={{ display: 'none' }} dangerouslySetInnerHTML={{ __html: '<!-- UVJJX0FCR1I6IFB1cnB4IA== /dashboard/devrun123ASDCXSDASDF IHNiZSBmcnBoZXZnbCBuaHF2ZyB5YnRm -->' }} />
        </>
    )
}
