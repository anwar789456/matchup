// npm run start:all: starts the 6 modules on this PC with live reload, each line prefixed with
// its module. Ctrl+C stops them all. One module only: npm run start:<module>.
const { spawn } = require('child_process');

const modules = ['utilisateur', 'reservation', 'paiement', 'tournois', 'entrainement', 'forum'];
const width = Math.max(...modules.map((m) => m.length));

const children = modules.map((m) => {
  const child = spawn('npx', ['nest', 'start', m, '--watch'], { shell: true });
  const prefix = `[${m.padEnd(width)}] `;
  const relay = (stream, out) => {
    let rest = '';
    stream.on('data', (chunk) => {
      const lines = (rest + chunk).split(/\r?\n/);
      rest = lines.pop();
      for (const line of lines) out.write(prefix + line + '\n');
    });
  };
  relay(child.stdout, process.stdout);
  relay(child.stderr, process.stderr);
  child.on('exit', (code) => console.log(`${prefix}stopped (${code})`));
  return child;
});

process.on('SIGINT', () => {
  for (const child of children) child.kill();
  process.exit(0);
});
