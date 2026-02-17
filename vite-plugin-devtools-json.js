import path from 'path'

export default function devtoolsJsonPlugin() {
    const uuid = process.env.DEVTOOLS_WORKSPACE_UUID || "d9cf460b-b9d3-42f0-9107-e69fa89ef5c6"
    const rootDir = process.cwd()

    // default base (will be overwritten by configResolved)
    let base = '/'

    return {
        name: 'devtools-json',
        enforce: 'pre',

        // capture the actual base from your Vite config (e.g. '/vite-assets/')
        configResolved(config) {
            base = config.base || '/'
            if (!base.endsWith('/')) base += '/'
        },

        // add a haml2erb-only middleware
        configureServer(server) {
            // serve at `${base}.well-known/appspecific/com.chrome.devtools.json`
            const endpoint = path.posix.join(
                base,
                '.well-known',
                'appspecific',
                'com.chrome.devtools.json'
            )

            server.middlewares.use(endpoint, (req, res) => {
                res.setHeader('Content-Type', 'application/json')
                res.end(JSON.stringify({
                    workspace: {
                        uuid,
                        root: rootDir
                    }
                }))
            })
        },
    }
}
