/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  typescript: {
    ignoreBuildErrors: true,
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
  experimental: {
    serverActions: { allowedOrigins: ['*'] }
  },
  async rewrites() {
    return [
      {
        source: '/uploads/:path*',
        destination: `${process.env.API_BASE_URL || process.env.NEXT_PUBLIC_API_BASE_URL}/uploads/:path*`,
      },
    ];
  },
};

export default nextConfig;
