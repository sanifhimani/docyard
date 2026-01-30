(function () {
  var ssePort = window.__DOCYARD_SSE_PORT__;
  if (!ssePort) return;

  var url = 'http://127.0.0.1:' + ssePort + '/';
  var eventSource = new EventSource(url);

  eventSource.addEventListener('reload', function (event) {
    var data = JSON.parse(event.data);
    if (data.type === 'content') {
      console.log('[Docyard] Content updated');
      reloadContent();
    } else {
      console.log('[Docyard] Full reload');
      location.reload();
    }
  });

  eventSource.onerror = function () {
    eventSource.close();
  };

  function reloadContent() {
    fetch(location.href)
      .then(function (response) { return response.text(); })
      .then(function (html) {
        var parser = new DOMParser();
        var newDoc = parser.parseFromString(html, 'text/html');
        var newContent = newDoc.querySelector('.content');
        var currentContent = document.querySelector('.content');

        if (newContent && currentContent) {
          currentContent.innerHTML = newContent.innerHTML;
          if (window.Prism) window.Prism.highlightAll();
          if (window.docyardTOC) window.docyardTOC.init();
          updateErrorOverlay(newDoc);
        } else {
          location.reload();
        }
      })
      .catch(function () {
        location.reload();
      });
  }

  function updateErrorOverlay(newDoc) {
    var newOverlay = newDoc.getElementById('docyard-error-overlay');
    var currentOverlay = document.getElementById('docyard-error-overlay');

    var newData = newOverlay ? newOverlay.dataset : null;
    var currentData = currentOverlay ? currentOverlay.dataset : null;

    var changed = diagnosticsChanged(newData, currentData);
    if (!changed) return;

    if (newOverlay && window.docyardErrorOverlay && window.docyardErrorOverlay.update) {
      window.docyardErrorOverlay.update(newOverlay.dataset);
    } else {
      location.reload();
    }
  }

  function diagnosticsChanged(newData, currentData) {
    if (!newData && !currentData) return false;
    if (!newData || !currentData) return true;
    return newData.errorCount !== currentData.errorCount ||
      newData.warningCount !== currentData.warningCount ||
      newData.diagnostics !== currentData.diagnostics;
  }
})();
