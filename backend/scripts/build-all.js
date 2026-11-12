// npm run build: builds the 6 modules one after the other (nest build <module>).
const { execSync } = require('child_process');

const modules = ['utilisateur', 'reservation', 'paiement', 'tournois', 'entrainement', 'forum'];
for (const m of modules) {
  console.log(`\n> nest build ${m}`);
  execSync(`npx nest build ${m}`, { stdio: 'inherit' });
}
