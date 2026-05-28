const express = require('express');
const { WebSocketServer } = require('ws');
const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ─── Configuration ────────────────────────────────────────────────────────────

const PS_TOOL = '/Users/dDenizon/Desktop/Projects/ps_tool/ps_tool';
const REGISTRY_PATH = path.join(os.homedir(), '.ps_tool', 'shops.txt');

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Lit le registre des shops depuis ~/.ps_tool/shops.txt
 * Format : shop_name|shop_path|prestashop_version|http_port|https_port
 */
function readRegistry() {
  if (!fs.existsSync(REGISTRY_PATH)) return [];

  const lines = fs.readFileSync(REGISTRY_PATH, 'utf8').split('\n').filter(Boolean);
  return lines.map(line => {
    const [name, shopPath, version, httpPort, httpsPort] = line.split('|');
    if (!name) return null;
    return { name, path: shopPath, version: version || 'N/A', httpPort: httpPort || '', httpsPort: httpsPort || '' };
  }).filter(Boolean);
}

/**
 * Construit l'URL d'un shop depuis ses ports
 */
function buildShopUrl(name, httpPort, httpsPort) {
  if (httpsPort && /^\d+$/.test(httpsPort)) {
    return httpsPort === '443'
      ? `https://${name}.ddev.site`
      : `https://${name}.ddev.site:${httpsPort}`;
  }
  if (httpPort && /^\d+$/.test(httpPort)) {
    return httpPort === '80'
      ? `http://${name}.ddev.site`
      : `http://${name}.ddev.site:${httpPort}`;
  }
  return null;
}

/**
 * Récupère l'état de tous les projets ddev en un seul appel
 * Retourne un Map { projectName -> 'running'|'stopped' }
 */
function getDdevStatus() {
  return new Promise((resolve) => {
    const proc = spawn('ddev', ['list', '--json-output'], { timeout: 10000 });
    let stdout = '';
    let stderr = '';
    proc.stdout.on('data', d => { stdout += d; });
    proc.stderr.on('data', d => { stderr += d; });
    proc.on('close', (code) => {
      const statusMap = new Map();
      if (code === 0 && stdout) {
        try {
          const parsed = JSON.parse(stdout);
          const items = parsed.raw || parsed.items || parsed || [];
          const arr = Array.isArray(items) ? items : [];
          for (const item of arr) {
            const n = item.name || item.approot;
            const s = (item.status || item.status_desc || '').toLowerCase();
            if (n) statusMap.set(n, s.includes('running') || s.includes('ok') ? 'running' : 'stopped');
          }
        } catch (_) {
          // fallback : parse texte
          parseDdevListText(stdout, statusMap);
        }
      } else {
        // fallback texte
        parseDdevListText(stderr + stdout, statusMap);
      }
      resolve(statusMap);
    });
    proc.on('error', () => resolve(new Map()));
  });
}

function parseDdevListText(text, map) {
  const lines = text.split('\n');
  for (const line of lines) {
    // Ligne type : │ shop9  │ running │
    const match = line.match(/[│|]\s*(\S+)\s*[│|]\s*(running|stopped|starting|ok)/i);
    if (match) {
      const name = match[1];
      const status = match[2].toLowerCase();
      map.set(name, status.includes('running') || status.includes('ok') ? 'running' : 'stopped');
    }
  }
}

/**
 * Lit le nom ddev d'un projet depuis son config.yaml
 */
function getDdevProjectName(shopPath) {
  const configPath = path.join(shopPath, '.ddev', 'config.yaml');
  if (!fs.existsSync(configPath)) return null;
  const content = fs.readFileSync(configPath, 'utf8');
  const match = content.match(/^name:\s*["']?([^"'\s\n]+)["']?/m);
  return match ? match[1] : null;
}

// ─── REST API ─────────────────────────────────────────────────────────────────

/**
 * GET /api/shops
 * Retourne la liste des shops avec leur statut
 */
app.get('/api/shops', async (req, res) => {
  try {
    const shops = readRegistry();
    const ddevStatus = await getDdevStatus();

    const result = shops
      .filter(s => fs.existsSync(s.path))
      .map(shop => {
        const projectName = getDdevProjectName(shop.path) || shop.name;
        const status = ddevStatus.get(projectName) || 'stopped';
        const url = buildShopUrl(shop.name, shop.httpPort, shop.httpsPort);

        return {
          name: shop.name,
          path: shop.path,
          version: shop.version,
          httpPort: shop.httpPort,
          httpsPort: shop.httpsPort,
          url,
          status,  // 'running' | 'stopped'
        };
      });

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * POST /api/shops/:name/start
 */
app.post('/api/shops/:name/start', (req, res) => {
  res.json({ ok: true, message: `Démarrage de ${req.params.name} lancé via WebSocket` });
});

/**
 * POST /api/shops/:name/stop
 */
app.post('/api/shops/:name/stop', (req, res) => {
  res.json({ ok: true, message: `Arrêt de ${req.params.name} lancé via WebSocket` });
});

/**
 * POST /api/shops/:name/open
 * Retourne l'URL du shop
 */
app.post('/api/shops/:name/open', (req, res) => {
  const shops = readRegistry();
  const shop = shops.find(s => s.name === req.params.name);
  if (!shop) return res.status(404).json({ error: 'Shop non trouvé' });

  const url = buildShopUrl(shop.name, shop.httpPort, shop.httpsPort);
  if (!url) return res.status(400).json({ error: 'Impossible de déterminer l\'URL (ports manquants)' });

  res.json({ url });
});

/**
 * POST /api/shops/:name/open-admin
 * Retourne l'URL du back-office (détecte le dossier admin renommé)
 */
app.post('/api/shops/:name/open-admin', (req, res) => {
  const shops = readRegistry();
  const shop = shops.find(s => s.name === req.params.name);
  if (!shop) return res.status(404).json({ error: 'Shop non trouvé' });

  const baseUrl = buildShopUrl(shop.name, shop.httpPort, shop.httpsPort);
  if (!baseUrl) return res.status(400).json({ error: 'Impossible de déterminer l\'URL (ports manquants)' });

  // Détecter le dossier admin (peut être renommé ex: admin4k2p9x)
  // PS 9+ : public/admin*, PS 8.x et 1.7 : admin* à la racine
  let adminFolder = null;
  for (const searchPath of [path.join(shop.path, 'public'), shop.path]) {
    if (!fs.existsSync(searchPath)) continue;
    try {
      const entries = fs.readdirSync(searchPath, { withFileTypes: true });
      const found = entries.find(e =>
        e.isDirectory() &&
        e.name.startsWith('admin') &&
        !e.name.includes('-') &&
        fs.existsSync(path.join(searchPath, e.name, 'index.php'))
      );
      if (found) { adminFolder = found.name; break; }
    } catch (_) {}
  }

  const url = adminFolder ? `${baseUrl}/${adminFolder}` : baseUrl;
  res.json({ url, adminFolder });
});

/**
 * DELETE /api/shops/:name
 * Supprime les entrées orphelines via prune (supprime le shop du registre)
 */
app.delete('/api/shops/:name', (req, res) => {
  res.json({ ok: true, message: `Suppression de ${req.params.name} lancée via WebSocket` });
});

/**
 * POST /api/shops/install
 * Corps JSON : { name, version, fixtures, manual, adminEmail, adminPassword, ... }
 */
app.post('/api/shops/install', (req, res) => {
  res.json({ ok: true, message: 'Installation lancée via WebSocket' });
});

/**
 * POST /api/shops/:name/reinstall
 */
app.post('/api/shops/:name/reinstall', (req, res) => {
  res.json({ ok: true, message: `Réinstallation de ${req.params.name} lancée via WebSocket` });
});

// ─── WebSocket ────────────────────────────────────────────────────────────────

function sendMsg(ws, type, data) {
  if (ws.readyState === ws.OPEN) {
    ws.send(JSON.stringify({ type, data }));
  }
}

/**
 * Exécute une commande shell et stream le résultat ligne par ligne via WebSocket
 * @param {WebSocket} ws
 * @param {string} cmd - exécutable
 * @param {string[]} args
 * @param {object} options - options spawn (env, cwd...)
 */
function runStreamed(ws, cmd, args, options = {}) {
  return new Promise((resolve) => {
    sendMsg(ws, 'log', `$ ${cmd} ${args.join(' ')}`);

    const proc = spawn(cmd, args, {
      ...options,
      env: { ...process.env, ...(options.env || {}) },
    });

    let buffer = '';

    const processLine = (line) => {
      if (!line.trim()) return;
      // Colorier selon contenu
      if (/error|erreur|échec|failed|fail/i.test(line)) {
        sendMsg(ws, 'error', line);
      } else if (/success|succès|succés|✓|démarré|installé|terminé|ok\b/i.test(line)) {
        sendMsg(ws, 'success', line);
      } else if (/warning|attention|warn/i.test(line)) {
        sendMsg(ws, 'warning', line);
      } else {
        sendMsg(ws, 'log', line);
      }
    };

    const handleData = (chunk) => {
      buffer += chunk.toString();
      const lines = buffer.split('\n');
      buffer = lines.pop(); // garder le dernier fragment incomplet
      lines.forEach(processLine);
    };

    proc.stdout.on('data', handleData);
    proc.stderr.on('data', handleData);

    proc.on('close', (code) => {
      if (buffer) processLine(buffer);
      if (code === 0) {
        sendMsg(ws, 'done', `Commande terminée avec succès (code: ${code})`);
      } else {
        sendMsg(ws, 'done', `Commande terminée avec le code ${code}`);
      }
      resolve(code);
    });

    proc.on('error', (err) => {
      sendMsg(ws, 'error', `Erreur de lancement : ${err.message}`);
      sendMsg(ws, 'done', 'Commande échouée');
      resolve(1);
    });
  });
}

/**
 * Supprime un shop du registre (sans toucher au disque)
 */
function removeFromRegistry(shopName) {
  if (!fs.existsSync(REGISTRY_PATH)) return;
  const lines = fs.readFileSync(REGISTRY_PATH, 'utf8').split('\n').filter(Boolean);
  const filtered = lines.filter(l => !l.startsWith(shopName + '|'));
  fs.writeFileSync(REGISTRY_PATH, filtered.join('\n') + (filtered.length ? '\n' : ''));
}

wss.on('connection', (ws) => {
  ws.on('message', async (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw);
    } catch {
      sendMsg(ws, 'error', 'Message WebSocket invalide (JSON attendu)');
      return;
    }

    const { action, payload = {} } = msg;

    try {
      switch (action) {

        // ── Démarrer un shop ─────────────────────────────────────────────────
        case 'start': {
          const { name } = payload;
          if (!name) { sendMsg(ws, 'error', 'Nom du shop manquant'); return; }

          const shops = readRegistry();
          const shop = shops.find(s => s.name === name);
          if (!shop || !fs.existsSync(shop.path)) {
            sendMsg(ws, 'error', `Shop non trouvé: ${name}`);
            sendMsg(ws, 'done', '');
            return;
          }

          sendMsg(ws, 'log', `Démarrage du shop ${name}...`);
          await runStreamed(ws, 'ddev', ['start'], { cwd: shop.path });
          break;
        }

        // ── Arrêter un shop ──────────────────────────────────────────────────
        case 'stop': {
          const { name } = payload;
          if (!name) { sendMsg(ws, 'error', 'Nom du shop manquant'); return; }

          const shops = readRegistry();
          const shop = shops.find(s => s.name === name);
          if (!shop || !fs.existsSync(shop.path)) {
            sendMsg(ws, 'error', `Shop non trouvé: ${name}`);
            sendMsg(ws, 'done', '');
            return;
          }

          sendMsg(ws, 'log', `Arrêt du shop ${name}...`);
          await runStreamed(ws, 'ddev', ['stop'], { cwd: shop.path });
          break;
        }

        // ── Supprimer un shop du registre ────────────────────────────────────
        case 'delete': {
          const { name } = payload;
          if (!name) { sendMsg(ws, 'error', 'Nom du shop manquant'); return; }

          const shops = readRegistry();
          const shop = shops.find(s => s.name === name);

          if (shop && fs.existsSync(shop.path)) {
            sendMsg(ws, 'log', `Arrêt et suppression des conteneurs ddev de ${name}...`);
            await runStreamed(ws, 'ddev', ['delete', '--omit-snapshot', '--yes'], { cwd: shop.path });
          }

          sendMsg(ws, 'log', `Suppression de ${name} du registre...`);
          removeFromRegistry(name);
          sendMsg(ws, 'success', `Shop ${name} supprimé du registre`);
          sendMsg(ws, 'done', '');
          break;
        }

        // ── Installer un nouveau shop ─────────────────────────────────────────
        case 'install': {
          const {
            name,
            version = '9.0.2',
            fixtures = true,
            manual = false,
            adminEmail,
            adminPassword,
            shopNameOption,
            httpPort,
            httpsPort,
          } = payload;

          if (!name) { sendMsg(ws, 'error', 'Nom du shop manquant'); return; }

          // Construire le répertoire d'installation par défaut : ~/shops/<name>
          const shopDir = path.join(os.homedir(), 'shops', name);
          fs.mkdirSync(shopDir, { recursive: true });

          const args = [PS_TOOL, 'shop', 'install', name, version];
          if (httpPort) args.push('--router-http-port', httpPort);
          if (httpsPort) args.push('--router-https-port', httpsPort);
          if (adminEmail) args.push('--admin-email', adminEmail);
          if (adminPassword) args.push('--admin-password', adminPassword);
          if (shopNameOption) args.push('--shop-name', shopNameOption);
          if (!fixtures) args.push('--no-fixtures');
          if (manual) args.push('--manual');

          sendMsg(ws, 'log', `Installation de PrestaShop ${version} dans ${shopDir}...`);
          await runStreamed(ws, 'bash', args, { cwd: shopDir });
          break;
        }

        // ── Réinstaller un shop ───────────────────────────────────────────────
        case 'reinstall': {
          const {
            name,
            version,
            fixtures = true,
            manual = false,
            adminEmail,
            adminPassword,
          } = payload;

          if (!name) { sendMsg(ws, 'error', 'Nom du shop manquant'); return; }

          const shops = readRegistry();
          const shop = shops.find(s => s.name === name);
          if (!shop || !fs.existsSync(shop.path)) {
            sendMsg(ws, 'error', `Shop non trouvé: ${name}`);
            sendMsg(ws, 'done', '');
            return;
          }

          const args = [PS_TOOL, 'shop', 'reinstall', name, '--force'];
          if (version) args.push(version);
          if (adminEmail) args.push('--admin-email', adminEmail);
          if (adminPassword) args.push('--admin-password', adminPassword);
          if (!fixtures) args.push('--no-fixtures');
          if (manual) args.push('--manual');

          sendMsg(ws, 'log', `Réinstallation du shop ${name}...`);
          await runStreamed(ws, 'bash', args, { cwd: shop.path });
          break;
        }

        default:
          sendMsg(ws, 'error', `Action inconnue: ${action}`);
          sendMsg(ws, 'done', '');
      }
    } catch (err) {
      sendMsg(ws, 'error', `Erreur serveur: ${err.message}`);
      sendMsg(ws, 'done', '');
    }
  });
});

// ─── Démarrage ────────────────────────────────────────────────────────────────

const PORT = process.env.PORT || 7337;
server.listen(PORT, () => {
  console.log(`PS Tool Web UI démarré sur http://localhost:${PORT}`);
});
