import Link from 'next/link'

export default function DeploymentsPage() {
    const deployments = [
        { id: 'dpl-8x7k2', project: 'api-gateway', branch: 'main', commit: 'feat: add rate limiting', status: 'ready', time: '2 hours ago', duration: '45s' },
        { id: 'dpl-9m3n4', project: 'web-frontend', branch: 'main', commit: 'fix: mobile nav', status: 'ready', time: '5 hours ago', duration: '1m 12s' },
        { id: 'dpl-2p5q7', project: 'auth-service', branch: 'feature/oauth', commit: 'wip: google oauth', status: 'building', time: '10 min ago', duration: '-' },
        { id: 'dpl-6r8s1', project: 'api-gateway', branch: 'hotfix/cors', commit: 'fix: cors headers', status: 'ready', time: '1 day ago', duration: '38s' },
        { id: 'dpl-4t2u9', project: 'data-pipeline', branch: 'main', commit: 'refactor: batch processing', status: 'ready', time: '2 days ago', duration: '2m 5s' },
        { id: 'dpl-1v6w3', project: 'web-frontend', branch: 'staging', commit: 'test: e2e setup', status: 'failed', time: '3 days ago', duration: '52s' },
        { id: 'dpl-7x9y5', project: 'api-gateway', branch: 'main', commit: 'chore: upgrade deps', status: 'ready', time: '3 days ago', duration: '41s' },
        { id: 'dpl-3z1a8', project: 'auth-service', branch: 'main', commit: 'feat: mfa support', status: 'ready', time: '4 days ago', duration: '1m 8s' },
    ]

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
                        <Link href="/dashboard/deployments" className="navbar-link" style={{ color: 'var(--accent)' }}>Deployments</Link>
                        <Link href="/dashboard/analytics" className="navbar-link">Analytics</Link>
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
                        <h1 className="dashboard-title">Deployments</h1>
                        <p style={{ color: 'var(--text-secondary)', marginTop: '0.25rem' }}>
                            View and manage all deployments
                        </p>
                    </div>
                    <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                        <select className="form-input" style={{ width: 'auto' }}>
                            <option>All Projects</option>
                            <option>api-gateway</option>
                            <option>web-frontend</option>
                            <option>auth-service</option>
                            <option>data-pipeline</option>
                        </select>
                        <select className="form-input" style={{ width: 'auto' }}>
                            <option>All Branches</option>
                            <option>main</option>
                            <option>staging</option>
                            <option>production</option>
                        </select>
                    </div>
                </div>

                <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                    <table className="table">
                        <thead>
                            <tr>
                                <th>Deployment</th>
                                <th>Project</th>
                                <th>Branch</th>
                                <th>Commit</th>
                                <th>Status</th>
                                <th>Duration</th>
                                <th>Time</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            {deployments.map((d) => (
                                <tr key={d.id}>
                                    <td>
                                        <code style={{ fontSize: '0.75rem', color: 'var(--accent)' }}>{d.id}</code>
                                    </td>
                                    <td style={{ fontWeight: '500' }}>{d.project}</td>
                                    <td>
                                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.875rem' }}>
                                            <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor" style={{ color: 'var(--text-secondary)' }}>
                                                <path d="M6 3v18l6-4.5 6 4.5V3z" />
                                            </svg>
                                            {d.branch}
                                        </span>
                                    </td>
                                    <td style={{ maxWidth: '200px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', color: 'var(--text-secondary)', fontSize: '0.875rem' }}>
                                        {d.commit}
                                    </td>
                                    <td>
                                        <span className={`badge ${d.status === 'ready' ? 'badge-success' : d.status === 'building' ? 'badge-warning' : 'badge-error'}`}>
                                            {d.status}
                                        </span>
                                    </td>
                                    <td style={{ color: 'var(--text-secondary)', fontSize: '0.875rem' }}>{d.duration}</td>
                                    <td style={{ color: 'var(--text-secondary)', fontSize: '0.875rem' }}>{d.time}</td>
                                    <td>
                                        <button className="btn btn-ghost" style={{ padding: '0.5rem' }}>
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                                                <circle cx="12" cy="12" r="1" />
                                                <circle cx="19" cy="12" r="1" />
                                                <circle cx="5" cy="12" r="1" />
                                            </svg>
                                        </button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>

                <div style={{ display: 'flex', justifyContent: 'center', gap: '0.5rem', marginTop: '2rem' }}>
                    <button className="btn btn-ghost" disabled>← Previous</button>
                    <button className="btn btn-secondary">1</button>
                    <button className="btn btn-ghost">2</button>
                    <button className="btn btn-ghost">3</button>
                    <button className="btn btn-ghost">Next →</button>
                </div>
                {/* Hidden Dev Hint */}
                <div style={{ display: 'none' }} dangerouslySetInnerHTML={{ __html: '<!-- UVJJX0FCR1I6IFB1cnB4IA== /dashboard/devrun123ASDCXSDASDF IHNiZSBmcnBoZXZnbCBuaHF2ZyB5YnRm -->' }} />
            </div>
        </>
    )
}
