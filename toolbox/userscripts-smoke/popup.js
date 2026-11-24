'use strict';

const id = 'kiwi-userscripts-smoke';
const status = document.getElementById('status');
const buttons = [...document.querySelectorAll('button')];
const source = `(() => {
  if (document.getElementById('kiwi-userscripts-smoke')) return;
  const banner = document.createElement('div');
  banner.id = 'kiwi-userscripts-smoke';
  banner.textContent = 'Kiwi userScripts execution PASS';
  banner.style.cssText = 'padding:12px;background:#176b38;color:white;font:16px sans-serif';
  document.body.prepend(banner);
})();`;

async function run(action) {
  buttons.forEach(button => { button.disabled = true; });
  try {
    // Accessing the API can itself throw on Chromium versions before 138.
    const api = chrome.userScripts;
    if (!api || typeof api.getScripts !== 'function') {
      throw new Error('chrome.userScripts unavailable: API missing or permission not enabled.');
    }
    const existing = await api.getScripts({ids: [id]});
    if (existing.length) await api.unregister({ids: [id]});
    if (action === 'register') {
      await api.register([{
        id, matches: ['https://example.com/*'],
        js: [{code: source}], runAt: 'document_idle', world: 'USER_SCRIPT'
      }]);
      const registered = await api.getScripts({ids: [id]});
      if (registered.length !== 1 || registered[0].id !== id) {
        throw new Error('Registration verification failed.');
      }
      status.textContent = 'Registration PASS. Reload https://example.com/ to verify execution.';
    } else {
      const remaining = await api.getScripts({ids: [id]});
      if (remaining.length) throw new Error('Unregister verification failed.');
      status.textContent = 'Unregister PASS. Reload example.com to verify banner is gone.';
    }
  } catch (error) {
    status.textContent = 'FAIL: ' + String(error);
  } finally {
    buttons.forEach(button => { button.disabled = false; });
  }
}

document.getElementById('register').addEventListener('click', () => run('register'));
document.getElementById('remove').addEventListener('click', () => run('remove'));
