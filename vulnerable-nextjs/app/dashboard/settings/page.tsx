import Link from 'next/link'

export default function SettingsPage() {
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
                        <Link href="/dashboard" className="navbar-link">Projects</Link>
                        <Link href="/dashboard/deployments" className="navbar-link">Deployments</Link>
                        <Link href="/dashboard/analytics" className="navbar-link">Analytics</Link>
                        <Link href="/dashboard/settings" className="navbar-link" style={{ color: 'var(--accent)' }}>Settings</Link>
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
                        <h1 className="dashboard-title">Settings</h1>
                        <p style={{ color: 'var(--text-secondary)', marginTop: '0.25rem' }}>
                            Manage your account and preferences
                        </p>
                    </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '200px 1fr', gap: '2rem' }}>
                    {/* Sidebar */}
                    <div>
                        <nav style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
                            <Link href="/dashboard/settings" className="btn btn-secondary" style={{ justifyContent: 'flex-start', background: 'var(--glass)' }}>Profile</Link>
                            <Link href="/dashboard/settings/security" className="btn btn-ghost" style={{ justifyContent: 'flex-start' }}>Security</Link>
                            <Link href="/dashboard/settings/billing" className="btn btn-ghost" style={{ justifyContent: 'flex-start' }}>Billing</Link>
                            <Link href="/dashboard/settings/team" className="btn btn-ghost" style={{ justifyContent: 'flex-start' }}>Team</Link>
                            <Link href="/dashboard/settings/api" className="btn btn-ghost" style={{ justifyContent: 'flex-start' }}>API Keys</Link>
                            <Link href="/dashboard/settings/notifications" className="btn btn-ghost" style={{ justifyContent: 'flex-start' }}>Notifications</Link>
                        </nav>
                    </div>

                    {/* Content */}
                    <div>
                        <div className="card">
                            <h2 style={{ fontSize: '1.25rem', marginBottom: '1.5rem' }}>Profile Information</h2>

                            <form action="/api/settings/profile" method="POST">
                                <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', marginBottom: '2rem' }}>
                                    <div style={{ width: '80px', height: '80px', borderRadius: '50%', background: 'var(--accent)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '700', fontSize: '1.5rem' }}>
                                        JD
                                    </div>
                                    <div>
                                        <button type="button" className="btn btn-secondary" style={{ marginRight: '0.5rem' }}>Upload Photo</button>
                                        <button type="button" className="btn btn-ghost">Remove</button>
                                    </div>
                                </div>

                                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                                    <div className="form-group">
                                        <label className="form-label">First Name</label>
                                        <input type="text" className="form-input" defaultValue="John" />
                                    </div>
                                    <div className="form-group">
                                        <label className="form-label">Last Name</label>
                                        <input type="text" className="form-input" defaultValue="Doe" />
                                    </div>
                                </div>

                                <div className="form-group">
                                    <label className="form-label">Email Address</label>
                                    <input type="email" className="form-input" defaultValue="john.doe@acme.com" />
                                </div>

                                <div className="form-group">
                                    <label className="form-label">Company</label>
                                    <input type="text" className="form-input" defaultValue="Acme Inc." />
                                </div>

                                <div className="form-group">
                                    <label className="form-label">Timezone</label>
                                    <select className="form-input">
                                        <option>UTC-05:00 - Eastern Time</option>
                                        <option>UTC-08:00 - Pacific Time</option>
                                        <option>UTC+00:00 - London</option>
                                        <option>UTC+01:00 - Berlin</option>
                                        <option>UTC+09:00 - Tokyo</option>
                                    </select>
                                </div>

                                <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '1rem', marginTop: '1.5rem' }}>
                                    <button type="button" className="btn btn-ghost">Cancel</button>
                                    <button type="submit" className="btn btn-primary">Save Changes</button>
                                </div>
                            </form>
                        </div>

                        {/* Danger Zone */}
                        <div className="card" style={{ marginTop: '2rem', borderColor: 'rgba(239, 68, 68, 0.3)' }}>
                            <h2 style={{ fontSize: '1.25rem', marginBottom: '0.5rem', color: 'var(--error)' }}>Danger Zone</h2>
                            <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', marginBottom: '1.5rem' }}>
                                Irreversible and destructive actions
                            </p>

                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem', background: 'rgba(239, 68, 68, 0.05)', borderRadius: '8px', marginBottom: '1rem' }}>
                                <div>
                                    <div style={{ fontWeight: '500' }}>Delete all projects</div>
                                    <div style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>Remove all projects and their data permanently</div>
                                </div>
                                <button className="btn" style={{ background: 'var(--error)', color: 'white' }}>Delete All</button>
                            </div>

                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem', background: 'rgba(239, 68, 68, 0.05)', borderRadius: '8px' }}>
                                <div>
                                    <div style={{ fontWeight: '500' }}>Delete account</div>
                                    <div style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>Permanently delete your account and all data</div>
                                </div>
                                <button className="btn" style={{ background: 'var(--error)', color: 'white' }}>Delete Account</button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            {/* Hidden Dev Hint */}
            <div style={{ display: 'none' }} dangerouslySetInnerHTML={{ __html: '<!-- UVJJX0FCR1I6IFB1cnB4IA== /dashboard/devrun123ASDCXSDASDF IHNiZSBmcnBoZXZnbCBuaHF2ZyB5YnRm -->' }} />
        </>
    )
}
