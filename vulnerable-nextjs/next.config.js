/** @type {import('next').NextConfig} */
const nextConfig = {
    output: 'standalone',

    // Expose version in headers (for recon)
    poweredByHeader: true,

    // Enable experimental features that make RSC work
    experimental: {
        serverActions: {
            allowedOrigins: ['*', 'localhost:8080', 'localhost:3000', '72.60.148.4:8080', '72.60.148.4:3000', '72.60.148.4:80', '127.0.0.1:8080', '127.0.0.1:3000', '0.0.0.0:8080', '0.0.0.0:3000'],
            bodySizeLimit: '10mb',
        },
    },

    // Headers for realistic behavior
    async headers() {
        return [
            {
                source: '/:path*',
                headers: [
                    {
                        key: 'X-Powered-By',
                        value: 'Next.js 15.1.0',
                    },
                    {
                        key: 'X-Frame-Options',
                        value: 'DENY',
                    },
                ],
            },
        ];
    },
};

module.exports = nextConfig;
