/* ─── PS Tool Web UI — app.js ─────────────────────────────────────────────── */

// ─── State ────────────────────────────────────────────────────────────────────

let shops = [];
let ws = null;
let pollingTimer = null;
const POLL_INTERVAL = 5000;

// ─── DOM refs ─────────────────────────────────────────────────────────────────

const shopsGrid      = document.getElementById('shops-grid');
const shopsCount     = document.getElementById('shops-count');
const loading        = document.getElementById('loading');
const emptyState     = document.getElementById('empty-state');
const terminalOverlay = document.getElementById('terminal-overlay');
const terminalBody   = document.getElementById('terminal-body');
const terminalLabel  = document.getElementById('terminal-label');
const terminalFooter = document.getElementById('terminal-footer');
const terminalDoneMsg = document.getElementById('terminal-done-msg');

// ─── Fetch shops ──────────────────────────────────────────────────────────────

async function fetchShops() {
  try {
    const res = await fetch('/api/shops');
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    shops = await res.json();
    renderShops();
  } catch (err) {
    console.error('Erreur chargement shops:', err);
  } finally {
    loading.hidden = true;
  }
}

function startPolling() {
  stopPolling();
  pollingTimer = setInterval(fetchShops, POLL_INTERVAL);
}

function stopPolling() {
  if (pollingTimer) { clearInterval(pollingTimer); pollingTimer = null; }
}

// ─── Render ───────────────────────────────────────────────────────────────────

function renderShops() {
  shopsCount.textContent = shops.length;

  if (shops.length === 0) {
    shopsGrid.hidden = true;
    emptyState.hidden = false;
    return;
  }

  emptyState.hidden = true;
  shopsGrid.hidden = false;

  shopsGrid.innerHTML = shops.map(renderCard).join('');

  // Bind card buttons
  shopsGrid.querySelectorAll('[data-action]').forEach(btn => {
    btn.addEventListener('click', handleCardAction);
  });
}

function renderCard(shop) {
  const status = shop.status || 'stopped'; // 'running' | 'stopped' | 'installing'
  const statusLabel = { running: 'Démarré', stopped: 'Arrêté', installing: 'Installation…' }[status] || status;

  const urlHtml = shop.url
    ? `<span class="shop-meta-row">
         <svg viewBox="0 0 20 20" fill="currentColor" width="12" height="12"><path fill-rule="evenodd" d="M12.586 4.586a2 2 0 112.828 2.828l-3 3a2 2 0 01-2.828 0 1 1 0 00-1.414 1.414 4 4 0 005.656 0l3-3a4 4 0 00-5.656-5.656l-1.5 1.5a1 1 0 101.414 1.414l1.5-1.5zm-5 5a2 2 0 012.828 0 1 1 0 101.414-1.414 4 4 0 00-5.656 0l-3 3a4 4 0 105.656 5.656l1.5-1.5a1 1 0 10-1.414-1.414l-1.5 1.5a2 2 0 11-2.828-2.828l3-3z" clip-rule="evenodd"/></svg>
         <a href="${esc(shop.url)}" target="_blank" rel="noopener">${esc(shop.url)}</a>
       </span>`
    : '';

  const ports = (shop.httpPort || shop.httpsPort)
    ? `<span class="shop-meta-row">
         <svg viewBox="0 0 20 20" fill="currentColor" width="12" height="12"><path fill-rule="evenodd" d="M3 6a3 3 0 013-3h10a1 1 0 01.8 1.6L14.25 7l2.55 2.4A1 1 0 0116 11H6a1 1 0 00-1 1v3a1 1 0 11-2 0V6z" clip-rule="evenodd"/></svg>
         ${shop.httpPort ? `HTTP :${esc(shop.httpPort)}` : ''}${shop.httpPort && shop.httpsPort ? ' · ' : ''}${shop.httpsPort ? `HTTPS :${esc(shop.httpsPort)}` : ''}
       </span>`
    : '';

  const isRunning = status === 'running';

  return `
<div class="shop-card" data-status="${esc(status)}" data-name="${esc(shop.name)}">
  <div class="shop-card-status-bar"></div>
  <div class="shop-card-body">
    <div class="shop-card-top">
      <span class="shop-card-name">${esc(shop.name)}</span>
      <span class="shop-card-version">PS ${esc(shop.version)}</span>
    </div>
    <div class="shop-card-meta">
      <span class="shop-meta-row">
        <span class="status-badge ${esc(status)}">
          <span class="status-dot"></span>
          ${esc(statusLabel)}
        </span>
      </span>
      ${urlHtml}
      ${ports}
    </div>
  </div>
  <div class="shop-card-footer">
    ${isRunning
      ? `<button class="btn btn-ghost btn-sm" data-action="stop" data-name="${esc(shop.name)}" title="Arrêter">
           <svg viewBox="0 0 20 20" fill="currentColor" width="13" height="13"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8 7a1 1 0 00-1 1v4a1 1 0 001 1h4a1 1 0 001-1V8a1 1 0 00-1-1H8z" clip-rule="evenodd"/></svg>
           Stop
         </button>
         <button class="btn btn-ghost btn-sm" data-action="open" data-name="${esc(shop.name)}" data-url="${esc(shop.url || '')}" title="Ouvrir le shop">
           <svg viewBox="0 0 20 20" fill="currentColor" width="13" height="13"><path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z"/><path d="M5 5a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2v-3a1 1 0 10-2 0v3H5V7h3a1 1 0 000-2H5z"/></svg>
           Shop
         </button>
         <button class="btn btn-ghost btn-sm" data-action="open-admin" data-name="${esc(shop.name)}" title="Ouvrir le back-office">
           <svg viewBox="0 0 20 20" fill="currentColor" width="13" height="13"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-6-3a2 2 0 11-4 0 2 2 0 014 0zm-2 4a5 5 0 00-4.546 2.916A5.986 5.986 0 0010 16a5.986 5.986 0 004.546-2.084A5 5 0 0010 11z" clip-rule="evenodd"/></svg>
           Admin
         </button>`
      : `<button class="btn btn-success btn-sm" data-action="start" data-name="${esc(shop.name)}" title="Démarrer">
           <svg viewBox="0 0 20 20" fill="currentColor" width="13" height="13"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clip-rule="evenodd"/></svg>
           Start
         </button>`}
    <span class="spacer"></span>
    <button class="btn btn-ghost btn-sm" data-action="reinstall" data-name="${esc(shop.name)}" data-version="${esc(shop.version)}" title="Réinstaller">
      <svg viewBox="0 0 20 20" fill="currentColor" width="13" height="13"><path fill-rule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clip-rule="evenodd"/></svg>
      Réinstaller
    </button>
    <button class="btn btn-ghost btn-sm" data-action="delete" data-name="${esc(shop.name)}" title="Supprimer du registre" style="color:var(--red)">
      <svg viewBox="0 0 20 20" fill="currentColor" width="13" height="13"><path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd"/></svg>
    </button>
  </div>
</div>`;
}

function esc(str) {
  if (str == null) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// ─── Card actions ─────────────────────────────────────────────────────────────

function handleCardAction(e) {
  const btn = e.currentTarget;
  const action = btn.dataset.action;
  const name   = btn.dataset.name;

  switch (action) {
    case 'start':
      openTerminal(`Démarrage — ${name}`);
      sendWs({ action: 'start', payload: { name } });
      break;

    case 'stop':
      openTerminal(`Arrêt — ${name}`);
      sendWs({ action: 'stop', payload: { name } });
      break;

    case 'open': {
      const url = btn.dataset.url;
      if (url) window.open(url, '_blank', 'noopener');
      else {
        fetch(`/api/shops/${encodeURIComponent(name)}/open`, { method: 'POST' })
          .then(r => r.json())
          .then(d => { if (d.url) window.open(d.url, '_blank', 'noopener'); })
          .catch(console.error);
      }
      break;
    }

    case 'open-admin': {
      fetch(`/api/shops/${encodeURIComponent(name)}/open-admin`, { method: 'POST' })
        .then(r => r.json())
        .then(d => { if (d.url) window.open(d.url, '_blank', 'noopener'); })
        .catch(console.error);
      break;
    }

    case 'reinstall':
      openReinstallModal(name, btn.dataset.version);
      break;

    case 'delete':
      if (confirm(`Supprimer "${name}" du registre ddev ?\n\nCette action arrête les conteneurs et retire le shop du registre. Les fichiers sur le disque ne sont pas supprimés.`)) {
        openTerminal(`Suppression — ${name}`);
        sendWs({ action: 'delete', payload: { name } });
      }
      break;
  }
}

// ─── WebSocket ────────────────────────────────────────────────────────────────

function connectWs() {
  const proto = location.protocol === 'https:' ? 'wss' : 'ws';
  ws = new WebSocket(`${proto}://${location.host}/ws`);

  ws.addEventListener('open', () => console.log('WS connecté'));
  ws.addEventListener('close', () => { ws = null; });
  ws.addEventListener('error', (e) => console.error('WS erreur', e));

  ws.addEventListener('message', (e) => {
    let msg;
    try { msg = JSON.parse(e.data); } catch { return; }
    handleWsMessage(msg);
  });
}

function sendWs(payload) {
  if (!ws || ws.readyState !== WebSocket.OPEN) {
    connectWs();
    // Attendre la connexion puis envoyer
    ws.addEventListener('open', () => ws.send(JSON.stringify(payload)), { once: true });
  } else {
    ws.send(JSON.stringify(payload));
  }
}

function handleWsMessage({ type, data }) {
  switch (type) {
    case 'log':     appendTermLine(data, 'log');     break;
    case 'success': appendTermLine(data, 'success'); break;
    case 'error':   appendTermLine(data, 'error');   break;
    case 'warning': appendTermLine(data, 'warning'); break;
    case 'done':
      appendTermLine(data || 'Terminé', 'done');
      terminalDoneMsg.textContent = data || 'Commande terminée';
      terminalFooter.hidden = false;
      // Rafraîchir la liste des shops
      fetchShops();
      break;
  }
}

// ─── Terminal ─────────────────────────────────────────────────────────────────

function openTerminal(label = 'Terminal') {
  terminalBody.innerHTML = '';
  terminalFooter.hidden = true;
  terminalLabel.textContent = label;
  terminalOverlay.hidden = false;
  stopPolling(); // stop polling pendant une commande active
  connectWs();
}

function closeTerminal() {
  terminalOverlay.hidden = true;
  startPolling();
}

function appendTermLine(text, type = 'log') {
  const line = document.createElement('span');
  line.className = `term-line term-${type}`;

  // Supprimer les codes ANSI de couleur (ex: \x1b[32m)
  line.textContent = text.replace(/\x1b\[[0-9;]*m/g, '');

  terminalBody.appendChild(line);
  terminalBody.appendChild(document.createTextNode('\n'));
  terminalBody.scrollTop = terminalBody.scrollHeight;
}

document.getElementById('terminal-close').addEventListener('click', closeTerminal);
document.getElementById('terminal-dismiss').addEventListener('click', closeTerminal);
document.getElementById('terminal-clear').addEventListener('click', () => {
  terminalBody.innerHTML = '';
  terminalFooter.hidden = true;
});

// ─── Modal : Nouveau shop ─────────────────────────────────────────────────────

const modalBackdrop  = document.getElementById('modal-backdrop');
const installForm    = document.getElementById('install-form');

function openInstallModal() {
  installForm.reset();
  modalBackdrop.hidden = false;
}

function closeInstallModal() {
  modalBackdrop.hidden = true;
}

document.getElementById('btn-new-shop').addEventListener('click', openInstallModal);
document.getElementById('btn-new-shop-empty').addEventListener('click', openInstallModal);
document.getElementById('modal-close').addEventListener('click', closeInstallModal);
document.getElementById('modal-cancel').addEventListener('click', closeInstallModal);

modalBackdrop.addEventListener('click', (e) => {
  if (e.target === modalBackdrop) closeInstallModal();
});

document.getElementById('modal-submit').addEventListener('click', () => {
  if (!installForm.reportValidity()) return;

  const data = new FormData(installForm);
  const payload = {
    name:          data.get('name'),
    version:       data.get('version'),
    fixtures:      data.get('fixtures') === 'on',
    manual:        data.get('manual') === 'on',
    adminEmail:    data.get('adminEmail') || undefined,
    adminPassword: data.get('adminPassword') || undefined,
    httpPort:      data.get('httpPort') || undefined,
    httpsPort:     data.get('httpsPort') || undefined,
  };

  closeInstallModal();
  openTerminal(`Installation — ${payload.name} (PS ${payload.version})`);
  sendWs({ action: 'install', payload });
});

// ─── Modal : Réinstaller ──────────────────────────────────────────────────────

const reinstallBackdrop = document.getElementById('reinstall-backdrop');
const reinstallForm     = document.getElementById('reinstall-form');

function openReinstallModal(name, version) {
  document.getElementById('reinstall-shop-name').textContent = name;
  document.getElementById('rf-name').value = name;
  // Présélectionner la version actuelle si elle existe dans le select
  const vSelect = document.getElementById('rf-version');
  const opt = [...vSelect.options].find(o => o.value === version);
  vSelect.value = opt ? version : '';
  document.getElementById('rf-fixtures').checked = true;
  document.getElementById('rf-manual').checked = false;
  reinstallBackdrop.hidden = false;
}

function closeReinstallModal() {
  reinstallBackdrop.hidden = true;
}

document.getElementById('reinstall-close').addEventListener('click', closeReinstallModal);
document.getElementById('reinstall-cancel').addEventListener('click', closeReinstallModal);

reinstallBackdrop.addEventListener('click', (e) => {
  if (e.target === reinstallBackdrop) closeReinstallModal();
});

document.getElementById('reinstall-submit').addEventListener('click', () => {
  const data = new FormData(reinstallForm);
  const name = data.get('name');
  const payload = {
    name,
    version:       data.get('version') || undefined,
    fixtures:      data.get('fixtures') === 'on',
    manual:        data.get('manual') === 'on',
  };

  closeReinstallModal();
  openTerminal(`Réinstallation — ${name}`);
  sendWs({ action: 'reinstall', payload });
});

// ─── Refresh button ───────────────────────────────────────────────────────────

document.getElementById('btn-refresh').addEventListener('click', () => {
  loading.hidden = false;
  shopsGrid.hidden = true;
  emptyState.hidden = true;
  fetchShops();
});

// ─── Keyboard shortcuts ───────────────────────────────────────────────────────

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    if (!terminalOverlay.hidden) { closeTerminal(); return; }
    if (!modalBackdrop.hidden)   { closeInstallModal(); return; }
    if (!reinstallBackdrop.hidden) { closeReinstallModal(); return; }
  }
});

// ─── Init ─────────────────────────────────────────────────────────────────────

(async () => {
  await fetchShops();
  startPolling();
  connectWs();
})();
