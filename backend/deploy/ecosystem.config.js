// pm2 processes on the server: one per module (each on its own port) + the deploy webhook.
const path = require('path');

const backend = path.resolve(__dirname, '..');
const modules = ['utilisateur', 'reservation', 'paiement', 'tournois', 'entrainement', 'forum'];

module.exports = {
  apps: [
    ...modules.map((name) => ({
      name,
      cwd: backend,
      script: `dist/apps/${name}/main.js`,
      max_memory_restart: '300M',
      env: { NODE_ENV: 'production' },
    })),
    {
      name: 'webhook',
      cwd: backend,
      script: 'deploy/webhook.js',
      env: { PORT: 9000 },
    },
  ],
};
