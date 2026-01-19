import Link from 'next/link'

export default function DocsPage() {
    const sections = [
        {
            title: 'Getting Started',
            icon: '🚀',
            links: [
                { title: 'Quick Start Guide', href: '/docs/quickstart' },
                { title: 'Installation', href: '/docs/installation' },
                { title: 'Your First Deployment', href: '/docs/first-deployment' },
                { title: 'Project Structure', href: '/docs/project-structure' },
            ]
        },
        {
            title: 'Core Concepts',
            icon: '📚',
            links: [
                { title: 'Projects & Environments', href: '/docs/projects' },
                { title: 'Deployments', href: '/docs/deployments' },
                { title: 'Domains & SSL', href: '/docs/domains' },
                { title: 'Environment Variables', href: '/docs/env-vars' },
            ]
        },
        {
            title: 'Infrastructure',
            icon: '☸️',
            links: [
                { title: 'Kubernetes Clusters', href: '/docs/kubernetes' },
                { title: 'Scaling & Resources', href: '/docs/scaling' },
                { title: 'Networking', href: '/docs/networking' },
                { title: 'Storage', href: '/docs/storage' },
            ]
        },
        {
            title: 'Security',
            icon: '🔐',
            links: [
                { title: 'Authentication', href: '/docs/auth' },
                { title: 'Secrets Management', href: '/docs/secrets' },
                { title: 'Access Control', href: '/docs/access-control' },
                { title: 'Audit Logs', href: '/docs/audit-logs' },
            ]
        },
        {
            title: 'Integrations',
            icon: '🔗',
            links: [
                { title: 'Git Providers', href: '/docs/git' },
                { title: 'CI/CD Pipelines', href: '/docs/cicd' },
                { title: 'Monitoring', href: '/docs/monitoring' },
                { title: 'Webhooks', href: '/docs/webhooks' },
            ]
        },
        {
            title: 'API Reference',
            icon: '⚙️',
            links: [
                { title: 'REST API', href: '/docs/api/rest' },
                { title: 'GraphQL API', href: '/docs/api/graphql' },
                { title: 'CLI Reference', href: '/docs/cli' },
                { title: 'SDKs', href: '/docs/sdks' },
            ]
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
                        <Link href="/features" className="navbar-link">Features</Link>
                        <Link href="/pricing" className="navbar-link">Pricing</Link>
                        <Link href="/docs" className="navbar-link" style={{ color: 'var(--accent)' }}>Documentation</Link>
                        <Link href="/status" className="navbar-link">Status</Link>
                    </div>

                    <div style={{ display: 'flex', gap: '1rem' }}>
                        <Link href="/login" className="btn btn-ghost">Sign In</Link>
                        <Link href="/register" className="btn btn-primary">Get Started</Link>
                    </div>
                </div>
            </nav>

            <section className="hero" style={{ paddingBottom: '2rem' }}>
                <div className="container">
                    <h1>Documentation</h1>
                    <p>Learn how to build, deploy, and scale with Cloud Fragment</p>

                    <div style={{ maxWidth: '500px', margin: '2rem auto 0' }}>
                        <input
                            type="search"
                            className="form-input"
                            placeholder="Search documentation..."
                            style={{ textAlign: 'center' }}
                        />
                    </div>
                </div>
            </section>

            <section className="container" style={{ paddingBottom: '4rem' }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '2rem' }}>
                    {sections.map((section, idx) => (
                        <div key={idx} className="card" style={{ padding: '1.5rem' }}>
                            <h3 style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1rem' }}>
                                <span style={{ fontSize: '1.5rem' }}>{section.icon}</span>
                                {section.title}
                            </h3>
                            <ul style={{ listStyle: 'none' }}>
                                {section.links.map((link, i) => (
                                    <li key={i}>
                                        <Link
                                            href={link.href}
                                            style={{
                                                display: 'block',
                                                padding: '0.75rem 0',
                                                color: 'var(--text-secondary)',
                                                textDecoration: 'none',
                                                borderBottom: i < section.links.length - 1 ? '1px solid var(--border)' : 'none',
                                                transition: 'color 0.2s'
                                            }}
                                            className="navbar-link"
                                        >
                                            {link.title}
                                        </Link>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    ))}
                </div>
            </section>

            <section className="container" style={{ paddingBottom: '4rem' }}>
                <div className="card" style={{ padding: '2rem' }}>
                    <h2 style={{ marginBottom: '1rem' }}>Popular Resources</h2>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '1rem' }}>
                        <div style={{ padding: '1rem', background: 'var(--glass)', borderRadius: '8px' }}>
                            <h4 style={{ marginBottom: '0.5rem' }}>📹 Video Tutorials</h4>
                            <p style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>Watch step-by-step guides</p>
                        </div>
                        <div style={{ padding: '1rem', background: 'var(--glass)', borderRadius: '8px' }}>
                            <h4 style={{ marginBottom: '0.5rem' }}>💬 Community Forum</h4>
                            <p style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>Get help from the community</p>
                        </div>
                        <div style={{ padding: '1rem', background: 'var(--glass)', borderRadius: '8px' }}>
                            <h4 style={{ marginBottom: '0.5rem' }}>📝 Changelog</h4>
                            <p style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>See what&apos;s new</p>
                        </div>
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
