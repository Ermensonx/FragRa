import Link from 'next/link'

export default function HomePage() {
    return (
        <>
            {/* Navbar */}
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
                        <Link href="/status" className="navbar-link">Status</Link>
                    </div>

                    <div style={{ display: 'flex', gap: '1rem' }}>
                        <Link href="/login" className="btn btn-ghost">Sign In</Link>
                        <Link href="/register" className="btn btn-primary">Get Started</Link>
                    </div>
                </div>
            </nav>

            {/* Hero Section */}
            <section className="hero">
                <div className="container">
                    <h1>Enterprise Cloud Infrastructure</h1>
                    <p>
                        Deploy, scale, and manage your applications with confidence.
                        Built for security-first organizations.
                    </p>
                    <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center' }}>
                        <Link href="/register" className="btn btn-primary">
                            Start Free Trial
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                <path d="M5 12h14M12 5l7 7-7 7" />
                            </svg>
                        </Link>
                        <Link href="/docs" className="btn btn-secondary">View Documentation</Link>
                    </div>
                </div>
            </section>

            {/* Stats */}
            <section className="container">
                <div className="stats-grid">
                    <div className="card stat-card">
                        <div className="stat-value">99.99%</div>
                        <div className="stat-label">Uptime SLA</div>
                    </div>
                    <div className="card stat-card">
                        <div className="stat-value">50+</div>
                        <div className="stat-label">Global Regions</div>
                    </div>
                    <div className="card stat-card">
                        <div className="stat-value">10M+</div>
                        <div className="stat-label">Deployments</div>
                    </div>
                    <div className="card stat-card">
                        <div className="stat-value">SOC 2</div>
                        <div className="stat-label">Certified</div>
                    </div>
                </div>
            </section>

            {/* Features */}
            <section className="container">
                <h2 style={{ textAlign: 'center', marginBottom: '1rem', fontSize: '2rem' }}>
                    Everything you need to scale
                </h2>
                <p style={{ textAlign: 'center', color: 'var(--text-secondary)', marginBottom: '2rem' }}>
                    Enterprise-grade infrastructure with developer-friendly tools
                </p>

                <div className="features-grid">
                    <div className="card feature-card">
                        <h3>
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" style={{ color: 'var(--accent)' }}>
                                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                            </svg>
                            Zero-Trust Security
                        </h3>
                        <p>
                            End-to-end encryption, automatic SSL certificates, and comprehensive
                            audit logs for complete visibility.
                        </p>
                    </div>

                    <div className="card feature-card">
                        <h3>
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" style={{ color: 'var(--accent)' }}>
                                <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
                            </svg>
                            Instant Deployments
                        </h3>
                        <p>
                            Deploy in seconds with our Git integration. Automatic previews,
                            rollbacks, and A/B testing built-in.
                        </p>
                    </div>

                    <div className="card feature-card">
                        <h3>
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" style={{ color: 'var(--accent)' }}>
                                <circle cx="12" cy="12" r="10" />
                            </svg>
                            Global Edge Network
                        </h3>
                        <p>
                            50+ edge locations worldwide for ultra-low latency.
                            Smart routing optimizes every request automatically.
                        </p>
                    </div>

                    <div className="card feature-card">
                        <h3>
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" style={{ color: 'var(--accent)' }}>
                                <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
                            </svg>
                            Kubernetes Native
                        </h3>
                        <p>
                            Full Kubernetes support with managed clusters, auto-scaling,
                            and seamless service mesh integration.
                        </p>
                    </div>

                    <div className="card feature-card">
                        <h3>
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" style={{ color: 'var(--accent)' }}>
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                                <circle cx="12" cy="7" r="4" />
                            </svg>
                            Team Collaboration
                        </h3>
                        <p>
                            Role-based access control, team workspaces, and real-time
                            collaboration on deployments.
                        </p>
                    </div>

                    <div className="card feature-card">
                        <h3>
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" style={{ color: 'var(--accent)' }}>
                                <path d="M22 12h-4l-3 9L9 3l-3 9H2" />
                            </svg>
                            Real-time Monitoring
                        </h3>
                        <p>
                            Comprehensive metrics, distributed tracing, and intelligent
                            alerting for complete observability.
                        </p>
                    </div>
                </div>
            </section>

            {/* CTA */}
            <section className="container" style={{ padding: '4rem 0' }}>
                <div className="card" style={{ textAlign: 'center', padding: '3rem' }}>
                    <h2 style={{ marginBottom: '1rem' }}>Ready to get started?</h2>
                    <p style={{ color: 'var(--text-secondary)', marginBottom: '2rem' }}>
                        Start your free trial today. No credit card required.
                    </p>
                    <Link href="/register" className="btn btn-primary">
                        Create Free Account
                    </Link>
                </div>
            </section>

            {/* Footer */}
            <footer className="footer">
                <div className="container">
                    <p>© 2024 Cloud Fragment. All rights reserved.</p>
                    <p style={{ marginTop: '0.5rem', fontSize: '0.75rem' }}>
                        <Link href="/privacy" className="auth-link">Privacy</Link>
                        {' · '}
                        <Link href="/terms" className="auth-link">Terms</Link>
                        {' · '}
                        <Link href="/security" className="auth-link">Security</Link>
                    </p>
                </div>
            </footer>
        </>
    )
}
