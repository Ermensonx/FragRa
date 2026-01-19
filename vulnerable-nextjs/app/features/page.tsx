import Link from 'next/link'

export default function FeaturesPage() {
    const features = [
        {
            icon: '🛡️',
            title: 'Zero-Trust Security',
            description: 'End-to-end encryption for all data in transit and at rest. Automatic SSL/TLS certificates with our managed PKI infrastructure.',
            details: ['mTLS between services', 'Automatic certificate rotation', 'FIPS 140-2 compliant', 'SOC 2 Type II certified']
        },
        {
            icon: '⚡',
            title: 'Instant Deployments',
            description: 'Deploy from Git in seconds with zero-downtime rolling updates. Automatic rollbacks if health checks fail.',
            details: ['Git push to deploy', 'Preview environments', 'Canary deployments', 'One-click rollbacks']
        },
        {
            icon: '🌍',
            title: 'Global Edge Network',
            description: '50+ edge locations worldwide for sub-50ms latency. Smart routing optimizes every request automatically.',
            details: ['50+ PoPs globally', 'Anycast routing', 'Auto-failover', 'DDoS protection included']
        },
        {
            icon: '☸️',
            title: 'Kubernetes Native',
            description: 'Full Kubernetes support with managed clusters. Auto-scaling, service mesh, and GitOps workflows built-in.',
            details: ['Managed K8s clusters', 'Istio service mesh', 'ArgoCD integration', 'Helm chart support']
        },
        {
            icon: '📊',
            title: 'Observability Suite',
            description: 'Real-time metrics, distributed tracing, and intelligent alerting. Full visibility into your entire stack.',
            details: ['Prometheus metrics', 'Jaeger tracing', 'Grafana dashboards', 'PagerDuty integration']
        },
        {
            icon: '🔐',
            title: 'Secrets Management',
            description: 'Secure vault for API keys, credentials, and certificates. Automatic rotation and audit logging.',
            details: ['Encrypted at rest', 'Version history', 'Access policies', 'Audit trails']
        },
        {
            icon: '🗄️',
            title: 'Managed Databases',
            description: 'PostgreSQL, MySQL, Redis, and MongoDB with automatic backups, replication, and point-in-time recovery.',
            details: ['Automatic backups', 'Multi-AZ replication', 'Connection pooling', 'Read replicas']
        },
        {
            icon: '🔄',
            title: 'CI/CD Pipelines',
            description: 'Built-in pipelines with parallelization, caching, and custom runners. Integrate with any Git provider.',
            details: ['GitHub/GitLab/Bitbucket', 'Docker layer caching', 'Parallel jobs', 'Custom runners']
        }
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
                        <Link href="/features" className="navbar-link" style={{ color: 'var(--accent)' }}>Features</Link>
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

            <section className="hero" style={{ paddingBottom: '3rem' }}>
                <div className="container">
                    <h1>Platform Features</h1>
                    <p>Everything you need to build, deploy, and scale modern applications</p>
                </div>
            </section>

            <section className="container" style={{ paddingBottom: '4rem' }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))', gap: '2rem' }}>
                    {features.map((feature, idx) => (
                        <div key={idx} className="card" style={{ padding: '2rem' }}>
                            <div style={{ fontSize: '2.5rem', marginBottom: '1rem' }}>{feature.icon}</div>
                            <h3 style={{ fontSize: '1.25rem', marginBottom: '0.75rem' }}>{feature.title}</h3>
                            <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem', lineHeight: '1.6' }}>{feature.description}</p>
                            <ul style={{ listStyle: 'none', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem' }}>
                                {feature.details.map((detail, i) => (
                                    <li key={i} style={{ fontSize: '0.875rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                                        <span style={{ color: 'var(--accent)' }}>✓</span>
                                        {detail}
                                    </li>
                                ))}
                            </ul>
                        </div>
                    ))}
                </div>
            </section>

            <section className="container" style={{ paddingBottom: '4rem' }}>
                <div className="card" style={{ textAlign: 'center', padding: '3rem' }}>
                    <h2 style={{ marginBottom: '1rem' }}>Ready to get started?</h2>
                    <p style={{ color: 'var(--text-secondary)', marginBottom: '2rem' }}>
                        Start your 14-day free trial. No credit card required.
                    </p>
                    <Link href="/register" className="btn btn-primary">Create Free Account</Link>
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
