import { getCurrentUser } from '../../actions'
import { redirect } from 'next/navigation'

export default async function DevRunPage() {
    const user = await getCurrentUser()
    if (!user) redirect('/')

    return (
        <div className="min-h-screen bg-gray-950 text-green-500 font-mono p-10">
            <div className="max-w-4xl mx-auto border border-green-800 p-6 bg-black shadow-[0_0_20px_rgba(0,255,0,0.1)]">
                <h1 className="text-2xl mb-6 border-b border-green-800 pb-2">
                    INTERNAL CHAT LOG [ENCRYPTED] - CHANNEL #DEVOPS
                </h1>

                <div className="space-y-4 text-sm opacity-80">
                    {/* ... (Diálogos anteriores sobre Hardening) ... */}

                    <div className="flex gap-4">
                        <span className="text-blue-400 font-bold">[SYSADMIN]</span>
                        <span>I've finished hardening the production containers. Removed curl, wget, netcat.</span>
                    </div>

                    <div className="flex gap-4">
                        <span className="text-yellow-400 font-bold">[DEV_ALEX]</span>
                        <span>Whatever. As long as I can still reach the dashboard. But hey, <span className="text-red-400">internal-api:8080</span> seems flaky today.</span>
                    </div>

                    {/* --- A NOVA DICA AQUI --- */}
                    <div className="flex gap-4">
                        <span className="text-blue-400 font-bold">[SYSADMIN]</span>
                        <span>Wait, Alex. I noticed the EdgeShield WAF config is outdated.</span>
                    </div>

                    <div className="flex gap-4">
                        <span className="text-yellow-400 font-bold">[DEV_ALEX]</span>
                        <span>Outdated how?</span>
                    </div>

                    <div className="flex gap-4">
                        <span className="text-blue-400 font-bold">[SYSADMIN]</span>
                        <span>It's blocking the root `/` path correctly, but you forgot to blacklist the legacy testing endpoints. <span className="text-red-400">/adfa</span>, <span className="text-red-400">/rsc</span> and <span className="text-red-400">/abc</span> are still bypassing the filter!</span>
                    </div>

                    <div className="flex gap-4">
                        <span className="text-yellow-400 font-bold">[DEV_ALEX]</span>
                        <span>Oops. Those were for the load balancer health checks. I'll remove them in the next deployment cycle.</span>
                    </div>

                    <div className="flex gap-4">
                        <span className="text-blue-400 font-bold">[SYSADMIN]</span>
                        <span>Do it NOW. If anyone discovers those paths, they bypass the main WAF rule.</span>
                    </div>
                    {/* ------------------------- */}

                    <div className="flex gap-4">
                        <span className="text-blue-400 font-bold">[SYSADMIN]</span>
                        <span>Also, remember: If you really need tools, upload static binaries to <span className="text-red-400">/tmp</span>. It's the only writable path.</span>
                    </div>

                    <div className="flex gap-4">
                        <span className="text-blue-400 font-bold">[SYSADMIN]</span>
                        <span>And regarding the Vault: I locked the file permissions. Use the `read_token` binary. It enforces a PTY check to stop script kiddies.</span>
                    </div>

                    <div className="flex gap-4">
                        <span className="text-blue-400 font-bold">[SYSADMIN]</span>
                        <span>FINAL WARNING: <span className="text-red-400">This Alpine environment requires STATIC binaries.</span> Don't blame me if your dynamic tools segfault. Also, I disabled `node -e` execution at the kernel level (wrapper actually) to stop RCE scripts. Upload your tools properly.</span>
                    </div>

                    <div className="flex gap-4">
                        <span className="text-red-500 font-bold">[SYSTEM]</span>
                        <span>Conversation archived.</span>
                    </div>
                </div>
            </div>
        </div>
    )
}