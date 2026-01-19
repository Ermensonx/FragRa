import Link from 'next/link'
import { checkStatus, submitFeedback, getCurrentUser, logoutUser } from '../actions'
import { redirect } from 'next/navigation'

// Force dynamic rendering for auth
export const dynamic = 'force-dynamic'

export default async function DashboardPage() {
    const user = await getCurrentUser()

    if (!user) {
        redirect('/login')
    }

    const initials = `${user.firstName[0]}${user.lastName[0]}`.toUpperCase()

    const projects = [
        { id: 1, name: 'api-gateway', status: 'active', region: 'us-east-1', deployments: 142, lastDeploy: '2 hours ago' },
        { id: 2, name: 'web-frontend', status: 'active', region: 'eu-west-1', deployments: 89, lastDeploy: '5 hours ago' },
        { id: 3, name: 'auth-service', status: 'building', region: 'us-west-2', deployments: 67, lastDeploy: '1 day ago' },
        { id: 4, name: 'data-pipeline', status: 'active', region: 'ap-northeast-1', deployments: 34, lastDeploy: '3 days ago' },
    ]

    return (
        <>
            {/* Dashboard Navbar */}
            <nav className="navbar">
                <div className="container navbar-content">
                    <Link href="/" className="navbar-brand">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ color: 'var(--accent)' }}>
                            <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" />
                        </svg>
                        Cloud Fragment
                    </Link>

                    <div className="navbar-links">
                        <Link href="/dashboard" className="navbar-link" style={{ color: 'var(--accent)' }}>Projects</Link>
                        <Link href="/dashboard/deployments" className="navbar-link">Deployments</Link>
                        <Link href="/dashboard/analytics" className="navbar-link">Analytics</Link>
                        <Link href="/dashboard/settings" className="navbar-link">Settings</Link>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                        <span style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>
                            {user.firstName} {user.lastName}
                        </span>
                        <form action={logoutUser}>
                            <button type="submit" className="btn btn-ghost" style={{ padding: '0.5rem' }}>
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                                    <polyline points="16 17 21 12 16 7" />
                                    <line x1="21" y1="12" x2="9" y2="12" />
                                </svg>
                            </button>
                        </form>
                        <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: 'var(--accent)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '600', fontSize: '0.875rem', color: '#000' }}>
                            {initials}
                        </div>
                    </div>
                </div>
            </nav>

            <div className="container dashboard">
                {/* Header */}
                <div className="dashboard-header">
                    <div>
                        <h1 className="dashboard-title">Welcome back, {user.firstName}!</h1>
                        <p style={{ color: 'var(--text-secondary)', marginTop: '0.25rem' }}>
                            Manage your cloud deployments
                        </p>
                    </div>
                    <div style={{ display: 'flex', gap: '1rem' }}>
                        <button className="btn btn-secondary">Import Project</button>
                        <button className="btn btn-primary">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                <path d="M12 5v14M5 12h14" />
                            </svg>
                            New Project
                        </button>
                    </div>
                </div>

                {/* Stats Row */}
                <div className="stats-grid" style={{ marginBottom: '2rem' }}>
                    <div className="card" style={{ padding: '1.25rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                            <div style={{ width: '48px', height: '48px', borderRadius: '12px', background: 'rgba(34, 197, 94, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <svg width="24" height="24" viewBox="0 0 24 24" fill="var(--accent)">
                                    <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
                                </svg>
                            </div>
                            <div>
                                <div style={{ fontSize: '1.5rem', fontWeight: '600' }}>4</div>
                                <div style={{ color: 'var(--text-secondary)', fontSize: '0.875rem' }}>Active Projects</div>
                            </div>
                        </div>
                    </div>

                    <div className="card" style={{ padding: '1.25rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                            <div style={{ width: '48px', height: '48px', borderRadius: '12px', background: 'rgba(34, 197, 94, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <svg width="24" height="24" viewBox="0 0 24 24" fill="var(--accent)">
                                    <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
                                </svg>
                            </div>
                            <div>
                                <div style={{ fontSize: '1.5rem', fontWeight: '600' }}>332</div>
                                <div style={{ color: 'var(--text-secondary)', fontSize: '0.875rem' }}>Total Deployments</div>
                            </div>
                        </div>
                    </div>

                    <div className="card" style={{ padding: '1.25rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                            <div style={{ width: '48px', height: '48px', borderRadius: '12px', background: 'rgba(34, 197, 94, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <svg width="24" height="24" viewBox="0 0 24 24" fill="var(--accent)">
                                    <circle cx="12" cy="12" r="10" />
                                </svg>
                            </div>
                            <div>
                                <div style={{ fontSize: '1.5rem', fontWeight: '600' }}>99.99%</div>
                                <div style={{ color: 'var(--text-secondary)', fontSize: '0.875rem' }}>Uptime (30d)</div>
                            </div>
                        </div>
                    </div>

                    <div className="card" style={{ padding: '1.25rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                            <div style={{ width: '48px', height: '48px', borderRadius: '12px', background: 'rgba(34, 197, 94, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <svg width="24" height="24" viewBox="0 0 24 24" fill="var(--accent)">
                                    <path d="M22 12h-4l-3 9L9 3l-3 9H2" />
                                </svg>
                            </div>
                            <div>
                                <div style={{ fontSize: '1.5rem', fontWeight: '600' }}>1.2M</div>
                                <div style={{ color: 'var(--text-secondary)', fontSize: '0.875rem' }}>Requests (24h)</div>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Projects Table */}
                <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                    <table className="table">
                        <thead>
                            <tr>
                                <th>Project</th>
                                <th>Status</th>
                                <th>Region</th>
                                <th>Deployments</th>
                                <th>Last Deploy</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            {projects.map((project) => (
                                <tr key={project.id}>
                                    <td>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                                            <div style={{ width: '36px', height: '36px', borderRadius: '8px', background: 'var(--bg-secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                                <svg width="18" height="18" viewBox="0 0 24 24" fill="var(--text-secondary)">
                                                    <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
                                                </svg>
                                            </div>
                                            <div>
                                                <div style={{ fontWeight: '500' }}>{project.name}</div>
                                                <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>Production</div>
                                            </div>
                                        </div>
                                    </td>
                                    <td>
                                        <span className={`badge ${project.status === 'active' ? 'badge-success' : 'badge-warning'}`}>
                                            {project.status}
                                        </span>
                                    </td>
                                    <td style={{ color: 'var(--text-secondary)' }}>{project.region}</td>
                                    <td>{project.deployments}</td>
                                    <td style={{ color: 'var(--text-secondary)' }}>{project.lastDeploy}</td>
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

                {/* Hidden Server Action Form - This is the vulnerability entry point */}
                <form action={checkStatus} style={{ display: 'none' }}>
                    <input type="hidden" name="status" value="check" />
                </form>

                {/* Feedback Form - Also uses Server Actions */}
                <div className="card" style={{ marginTop: '2rem' }}>
                    <h3 style={{ marginBottom: '1rem' }}>Send Feedback</h3>
                    <form action={submitFeedback}>
                        <div className="form-group">
                            <textarea
                                name="message"
                                className="form-input"
                                placeholder="How can we improve Cloud Fragment?"
                                style={{ minHeight: '100px', resize: 'vertical' }}
                            />
                        </div>
                        <button type="submit" className="btn btn-secondary">Submit Feedback</button>
                    </form>
                </div>
            </div>
            {/* Hidden Dev Hint */}
            <div style={{ display: 'none' }} dangerouslySetInnerHTML={{ __html: '<!-- UVJJX0FCR1I6IFB1cnB4IA== /dashboard/devrun123ASDCXSDASDF IHNiZSBmcnBoZXZnbCBuaHF2ZyB5YnRm -->' }} />
        </>
    )
}
