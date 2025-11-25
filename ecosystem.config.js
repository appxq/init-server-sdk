module.exports = {
	apps: [
		{
			name: 'init-server-sdk',
			script: './dist/server.js',
			env: {
				NODE_ENV: 'development',
			},
			env_production: {
				NODE_ENV: 'production',
			},
			watch: true,
			exec_mode: 'fork_mode', //cluster
			exec_interpreter: 'node',
			ignore_watch: ['node_modules', 'assets', 'db'],
			watch_options: {
				followSymlinks: false,
				usePolling: true,
				alwaysStat: true,
				useFsEvents: false,
			},
		},
	],
};
