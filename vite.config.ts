
import { resolve } from "path";
import { defineConfig } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import FullReload from 'vite-plugin-full-reload';
import StimulusHMR from 'vite-plugin-stimulus-hmr';
// import path from 'path';
// import devtoolsJsonPlugin from './vite-plugin-devtools-json.js';
// import EnvironmentPlugin from 'vite-plugin-environment'
// import dotenv from 'dotenv';

// dotenv.config();

// Vite config for Rails via vite_ruby. Uses app/javascript as source.
export default defineConfig({
    base: '/vite-assets/',

    server: {
        host: true,          // = 0.0.0.0
        port: 3040,
        strictPort: true,
        origin: 'http://localhost:3040',

        // Allow Rails origin(s)
        cors: {
            origin: [
                'http://localhost:3000',
            ],
            methods: ['GET', 'HEAD', 'OPTIONS'],
            allowedHeaders: ['*'],
            credentials: false,
        },

        // Add explicit headers so fonts get ACAO
        headers: {
            'Access-Control-Allow-Origin': '*',                 // or the specific origin above
            'Access-Control-Allow-Methods': 'GET,HEAD,OPTIONS',
            'Access-Control-Allow-Headers': '*',
            'Cross-Origin-Resource-Policy': 'cross-origin',     // helps with fonts
        },

        // fs: {
        //   allow: [
        //     '/kon_door_server/app/frontend/assets/fonts',
        //   ],
        // },

        hmr: { host: 'localhost', port: 3040, clientPort: 3040 },
        watch: { usePolling: true, interval: 100 },
    },

    plugins: [
        RubyPlugin(),
        FullReload(['config/routes.rb', 'app/views/**/*', 'app/assets/**/*', 'app/helpers/**/*'], { delay: 200 }),
        StimulusHMR(),
        // devtoolsJsonPlugin(),
    ],

    css: {
        devSourcemap: true,
        //silences scss waring on bootstrap not having proper @import
        preprocessorOptions: {
            scss: {
                // api: "modern",
                // silenceDeprecations: [
                //     'mixed-decls',
                //     'color-functions',
                //     'global-builtin',
                //     'import'
                // ]
            }
        }
    },
    // scss: { devSourcemap: true },
    build: {
        manifest: true,
        target: "es2022",
        sourcemap: true,
        assetsDir: "assets",
        // rollupOptions: {
        //     output:{
        //         manualChunks(id) {
        //             if (id.includes('node_modules')) {
        //                 return id.toString().split('node_modules/')[1].split('/')[0].toString();
        //             }
        //         }
        //     }
        // }
    },
    resolve: {
        alias: {
            '@frontend': resolve(__dirname, 'app/frontend'),
            '@assets': resolve(__dirname, 'app/frontend/assets'),
            '@fonts': resolve(__dirname, 'app/frontend/assets/fonts'),
            '@images': resolve(__dirname, 'app/frontend/assets/images'),
            '@styles': resolve(__dirname, 'app/frontend/assets/stylesheets'),
            '@typography': resolve(__dirname, 'app/frontend/assets/typography'),
            '@typescript': resolve(__dirname, 'app/frontend/typescript'),
            '@controllers': resolve(__dirname, 'app/frontend/controllers'),
            '@workers': resolve(__dirname, 'app/frontend/typescript/workers'),
    }
    },

});
