import Link from 'next/link'

export default function PricingPage() {
    const plans = [
        {
            name: 'Starter',
            price: '$0',
            period: 'forever',
            description: 'Perfect for side projects and learning',
            features: [
                '3 projects',
                '100 GB bandwidth/month',
                'Shared compute (1 vCPU, 512MB)',
                'Community support',
                'SSL certificates',
                'Git integration'
            ],
            cta: 'Start Free',
            highlight: false
        },
        {
            name: 'Pro',
            price: '$20',
            period: '/month',
            description: 'For professional developers and small teams',
            features: [
                'Unlimited projects',
                '1 TB bandwidth/month',
                'Dedicated compute (2 vCPU, 4GB)',
                'Email support (24h response)',
                'Custom domains',
                'Preview environments',
                'Team collaboration (5 seats)',
                'Analytics dashboard'
            ],
            cta: 'Start Free Trial',
            highlight: true
        },
        {
            name: 'Enterprise',
            price: 'Custom',
            period: '',
            description: 'For large organizations with advanced needs',
            features: [
                'Unlimited everything',
                'Custom bandwidth',
                'Dedicated clusters',
                '24/7 priority support',
                'SLA 99.99%',
                'SSO/SAML',
                'Audit logs',
                'Custom contracts',
                'Dedicated account manager',
                'On-premise option'
            ],
            cta: 'Contact Sales',
            highlight: false
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
                        <Link href="/pricing" className="navbar-link" style={{ color: 'var(--accent)' }}>Pricing</Link>
                        <Link href="/docs" className="navbar-link">Documentation</Link>
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
                    <h1>Simple, Transparent Pricing</h1>
                    <p>Start free, scale as you grow. No hidden fees.</p>
                </div>
            </section>

            <section className="container" style={{ paddingBottom: '4rem' }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '2rem', alignItems: 'start' }}>
                    {plans.map((plan, idx) => (
                        <div
                            key={idx}
                            className="card"
                            style={{
                                padding: '2rem',
                                border: plan.highlight ? '2px solid var(--accent)' : undefined,
                                position: 'relative'
                            }}
                        >
                            {plan.highlight && (
                                <div style={{
                                    position: 'absolute',
                                    top: '-12px',
                                    left: '50%',
                                    transform: 'translateX(-50%)',
                                    background: 'var(--accent)',
                                    color: '#000',
                                    padding: '0.25rem 1rem',
                                    borderRadius: '9999px',
                                    fontSize: '0.75rem',
                                    fontWeight: '600'
                                }}>
                                    MOST POPULAR
                                </div>
                            )}

                            <h3 style={{ fontSize: '1.25rem', marginBottom: '0.5rem' }}>{plan.name}</h3>
                            <div style={{ marginBottom: '0.5rem' }}>
                                <span style={{ fontSize: '2.5rem', fontWeight: '700' }}>{plan.price}</span>
                                <span style={{ color: 'var(--text-secondary)' }}>{plan.period}</span>
                            </div>
                            <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem', fontSize: '0.875rem' }}>
                                {plan.description}
                            </p>

                            <button
                                className={`btn ${plan.highlight ? 'btn-primary' : 'btn-secondary'}`}
                                style={{ width: '100%', marginBottom: '1.5rem' }}
                            >
                                {plan.cta}
                            </button>

                            <ul style={{ listStyle: 'none' }}>
                                {plan.features.map((feature, i) => (
                                    <li key={i} style={{
                                        fontSize: '0.875rem',
                                        color: 'var(--text-secondary)',
                                        display: 'flex',
                                        alignItems: 'center',
                                        gap: '0.75rem',
                                        padding: '0.5rem 0',
                                        borderBottom: i < plan.features.length - 1 ? '1px solid var(--border)' : 'none'
                                    }}>
                                        <span style={{ color: 'var(--accent)' }}>✓</span>
                                        {feature}
                                    </li>
                                ))}
                            </ul>
                        </div>
                    ))}
                </div>
            </section>

            <section className="container" style={{ paddingBottom: '4rem' }}>
                <div className="card" style={{ padding: '2rem' }}>
                    <h2 style={{ marginBottom: '1.5rem', textAlign: 'center' }}>Compare Plans</h2>
                    <div style={{ overflowX: 'auto' }}>
                        <table className="table">
                            <thead>
                                <tr>
                                    <th>Feature</th>
                                    <th>Starter</th>
                                    <th>Pro</th>
                                    <th>Enterprise</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr><td>Projects</td><td>3</td><td>Unlimited</td><td>Unlimited</td></tr>
                                <tr><td>Bandwidth</td><td>100 GB</td><td>1 TB</td><td>Custom</td></tr>
                                <tr><td>Team seats</td><td>1</td><td>5</td><td>Unlimited</td></tr>
                                <tr><td>Support</td><td>Community</td><td>Email</td><td>24/7 Priority</td></tr>
                                <tr><td>SLA</td><td>-</td><td>99.9%</td><td>99.99%</td></tr>
                                <tr><td>Audit logs</td><td>-</td><td>30 days</td><td>Unlimited</td></tr>
                                <tr><td>SSO/SAML</td><td>-</td><td>-</td><td>✓</td></tr>
                            </tbody>
                        </table>
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
