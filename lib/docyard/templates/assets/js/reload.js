(function () {
  let lastCheck = Date.now() / 1000;
  let basePollInterval = 500;
  let currentPollInterval = basePollInterval;
  let isReloading = false;
  let consecutiveFailures = 0;
  let serverWasDown = false;
  let timeoutId = null;

  async function fetchWithTimeout(resource, options = {}) {
    const { timeout = 5000 } = options;

    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), timeout);

    try {
      const response = await fetch(resource, {
        ...options,
        signal: controller.signal
      });
      clearTimeout(id);
      return response;
    } catch (error) {
      clearTimeout(id);
      throw error;
    }
  }

  async function checkForChanges() {
    if (isReloading) return;

    try {
      const response = await fetchWithTimeout(`/_docyard/reload?since=${lastCheck}`, { timeout: 3000 });
      const data = await response.json();
      lastCheck = data.timestamp;

      if (consecutiveFailures > 0) {
        consecutiveFailures = 0;
        currentPollInterval = basePollInterval;
        if (serverWasDown) {
          console.log('[Docyard] Server reconnected');
          serverWasDown = false;
        }
      }

      if (data.reload && !isReloading) {
        isReloading = true;
        console.log("[Docyard] Changes detected, hot reloading...");

        try {
          const resp = await fetchWithTimeout(window.location.href, { timeout: 5000 });
          const html = await resp.text();
          const parser = new DOMParser();
          const newDoc = parser.parseFromString(html, 'text/html');

          const oldMain = document.querySelector('main');
          const newMain = newDoc.querySelector('main');

          if (oldMain && newMain) {
            oldMain.innerHTML = newMain.innerHTML;
            console.log('[Docyard] Content updated via hot reload');
          } else {
            console.log('[Docyard] Layout changed, full reload required');
            window.location.reload();
            return;
          }

          isReloading = false;
        } catch (error) {
          console.error('[Docyard] Hot reload failed:', error);
          console.log('[Docyard] Falling back to full reload');
          window.location.reload();
        }
      }
    } catch (error) {
      consecutiveFailures++;

      if (consecutiveFailures === 1) {
        console.log('[Docyard] Server disconnected - live reload paused');
        serverWasDown = true;
      }

      if (consecutiveFailures >= 3) {
        console.log('[Docyard] Stopped polling. Refresh page when server restarts.');
        return;
      }

      currentPollInterval = Math.min(basePollInterval * Math.pow(2, consecutiveFailures - 1), 5000);

      isReloading = false;
    }

    timeoutId = setTimeout(checkForChanges, currentPollInterval);
  }

  checkForChanges();
  console.log("[Docyard] Hot reload initialized");
})();
