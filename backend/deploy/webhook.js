// GitHub push webhook: POST /webhook runs deploy.sh in the background (only changed modules).
// GET /webhook/log shows the end of the deploy log. No dependencies.
const { spawn } = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const http = require('http');
const path = require('path');

const PORT = Number(process.env.PORT || 9000);
const SECRET = process.env.WEBHOOK_SECRET || ''; // optional; set the same value on GitHub
const LOG = process.env.DEPLOY_LOG || '/var/log/matchup/deploy.log';
const DEPLOY = path.join(__dirname, 'deploy.sh');

function deploy(reason) {
  console.log(new Date().toISOString(), 'deploy:', reason);
  spawn('bash', [DEPLOY], { detached: true, stdio: 'ignore' }).unref();
}

function validSignature(body, header) {
  if (!SECRET) return true;
  const expected = 'sha256=' + crypto.createHmac('sha256', SECRET).update(body).digest('hex');
  return (
    typeof header === 'string' &&
    header.length === expected.length &&
    crypto.timingSafeEqual(Buffer.from(header), Buffer.from(expected))
  );
}

http
  .createServer((req, res) => {
    if (req.method === 'GET' && req.url.startsWith('/webhook/log')) {
      fs.readFile(LOG, 'utf8', (err, text) => {
        res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end(err ? 'Pas encore de déploiement.\n' : text.split('\n').slice(-200).join('\n'));
      });
      return;
    }
    if (req.method !== 'POST' || !req.url.startsWith('/webhook')) {
      res.writeHead(404).end();
      return;
    }
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => {
      const body = Buffer.concat(chunks);
      if (!validSignature(body, req.headers['x-hub-signature-256'])) {
        res.writeHead(401).end('bad signature');
        return;
      }
      const event = req.headers['x-github-event'];
      if (event === 'ping') {
        res.writeHead(200).end('pong');
        return;
      }
      let ref = '';
      try {
        ref = JSON.parse(body.toString('utf8')).ref || '';
      } catch {
        /* form-encoded or empty payload: deploy anyway */
      }
      if (event === 'push' && ref && ref !== 'refs/heads/main') {
        res.writeHead(202).end(`ignored ${ref}`);
        return;
      }
      deploy(`${event || 'manual'} ${ref}`);
      res.writeHead(202).end('deploying');
    });
  })
  .listen(PORT, '127.0.0.1', () => console.log(`webhook listening on 127.0.0.1:${PORT}`));
